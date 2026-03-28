"""Activity log API — users can view their own activity history."""
from __future__ import annotations


from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.deps import get_current_user_id, get_db
from app.models.activity_log import ActivityLog
from app.schemas.activity_log import ActivityLogOut, ActivityLogPage

router = APIRouter()


@router.get("", response_model=ActivityLogPage)
def list_my_activity(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Return the current user's activity log (paginated, newest first)."""
    base = select(ActivityLog).where(ActivityLog.user_id == user_id)
    total = db.execute(select(func.count()).select_from(base.subquery())).scalar() or 0

    rows = (
        db.execute(
            base.order_by(ActivityLog.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        .scalars()
        .all()
    )

    return ActivityLogPage(
        items=[
            ActivityLogOut(
                id=str(r.id),
                action=r.action,
                detail=r.detail,
                ip_address=r.ip_address,
                created_at=r.created_at,
            )
            for r in rows
        ],
        total=total,
        page=page,
        page_size=page_size,
    )
