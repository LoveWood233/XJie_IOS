"""Admin management endpoints — stats, user list, conversations, omics uploads."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.deps import get_db, require_admin
from app.models.conversation import ChatMessage, Conversation
from app.models.meal import Meal
from app.models.omics import OmicsUpload
from app.models.user import User
from app.schemas.admin import AdminConversationItem, AdminOmicsItem, AdminStats, AdminUserItem

router = APIRouter()


# ── Dashboard stats ──────────────────────────────────────────


@router.get("/stats", response_model=AdminStats)
def admin_stats(
    _admin_id: int = Depends(require_admin),
    db: Session = Depends(get_db),
):
    total_users = db.scalar(select(func.count()).select_from(User).where(User.deleted == 0)) or 0

    since_7d = datetime.now(timezone.utc) - timedelta(days=7)
    active_users_7d = db.scalar(
        select(func.count(func.distinct(Conversation.user_id)))
        .where(Conversation.updated_at >= since_7d)
    ) or 0

    total_conversations = db.scalar(select(func.count()).select_from(Conversation)) or 0
    total_messages = db.scalar(select(func.count()).select_from(ChatMessage)) or 0
    total_omics = db.scalar(select(func.count()).select_from(OmicsUpload)) or 0
    total_meals = db.scalar(select(func.count()).select_from(Meal)) or 0

    return AdminStats(
        total_users=total_users,
        active_users_7d=active_users_7d,
        total_conversations=total_conversations,
        total_messages=total_messages,
        total_omics_uploads=total_omics,
        total_meals=total_meals,
    )


# ── User list ────────────────────────────────────────────────


@router.get("/users", response_model=list[AdminUserItem])
def admin_users(
    _admin_id: int = Depends(require_admin),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
):
    offset = (page - 1) * size

    # Subquery: conversation count per user
    conv_sub = (
        select(Conversation.user_id, func.count().label("conv_count"))
        .group_by(Conversation.user_id)
        .subquery()
    )
    # Subquery: message count per user
    msg_sub = (
        select(
            Conversation.user_id,
            func.count(ChatMessage.id).label("msg_count"),
            func.max(ChatMessage.created_at).label("last_active"),
        )
        .join(ChatMessage, ChatMessage.conversation_id == Conversation.id)
        .group_by(Conversation.user_id)
        .subquery()
    )

    stmt = (
        select(
            User.id,
            User.phone,
            User.username,
            User.is_admin,
            User.created_at,
            func.coalesce(conv_sub.c.conv_count, 0).label("conversation_count"),
            func.coalesce(msg_sub.c.msg_count, 0).label("message_count"),
            msg_sub.c.last_active,
        )
        .outerjoin(conv_sub, conv_sub.c.user_id == User.id)
        .outerjoin(msg_sub, msg_sub.c.user_id == User.id)
        .where(User.deleted == 0)
        .order_by(User.id.desc())
        .offset(offset)
        .limit(size)
    )

    rows = db.execute(stmt).all()
    return [
        AdminUserItem(
            id=r.id,
            phone=r.phone,
            username=r.username,
            is_admin=r.is_admin or False,
            created_at=r.created_at,
            conversation_count=r.conversation_count,
            message_count=r.message_count,
            last_active=r.last_active,
        )
        for r in rows
    ]


# ── Conversation list ────────────────────────────────────────


@router.get("/conversations", response_model=list[AdminConversationItem])
def admin_conversations(
    _admin_id: int = Depends(require_admin),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
):
    offset = (page - 1) * size

    stmt = (
        select(
            Conversation.id,
            Conversation.user_id,
            User.username,
            Conversation.title,
            Conversation.message_count,
            Conversation.created_at,
            Conversation.updated_at,
        )
        .join(User, User.id == Conversation.user_id)
        .order_by(Conversation.updated_at.desc())
        .offset(offset)
        .limit(size)
    )
    rows = db.execute(stmt).all()
    return [
        AdminConversationItem(
            id=r.id,
            user_id=r.user_id,
            username=r.username,
            title=r.title,
            message_count=r.message_count,
            created_at=r.created_at,
            updated_at=r.updated_at,
        )
        for r in rows
    ]


# ── Omics uploads ────────────────────────────────────────────


@router.get("/omics", response_model=list[AdminOmicsItem])
def admin_omics(
    _admin_id: int = Depends(require_admin),
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
):
    offset = (page - 1) * size

    stmt = (
        select(
            OmicsUpload.id,
            OmicsUpload.user_id,
            User.username,
            OmicsUpload.omics_type,
            OmicsUpload.file_name,
            OmicsUpload.file_size,
            OmicsUpload.risk_level,
            OmicsUpload.llm_summary,
            OmicsUpload.created_at,
        )
        .join(User, User.id == OmicsUpload.user_id)
        .order_by(OmicsUpload.created_at.desc())
        .offset(offset)
        .limit(size)
    )
    rows = db.execute(stmt).all()
    return [
        AdminOmicsItem(
            id=r.id,
            user_id=r.user_id,
            username=r.username,
            omics_type=r.omics_type,
            file_name=r.file_name,
            file_size=r.file_size,
            risk_level=r.risk_level,
            llm_summary=r.llm_summary,
            created_at=r.created_at,
        )
        for r in rows
    ]


# ── Set user admin flag ──────────────────────────────────────


@router.patch("/users/{user_id}/admin")
def toggle_admin(
    user_id: int,
    admin_id: int = Depends(require_admin),
    db: Session = Depends(get_db),
):
    if user_id == admin_id:
        raise HTTPException(status_code=400, detail="Cannot change own admin status")
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_admin = not user.is_admin
    db.commit()
    return {"id": user.id, "is_admin": user.is_admin}
