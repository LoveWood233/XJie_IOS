from datetime import datetime

from pydantic import BaseModel


class AdminStats(BaseModel):
    total_users: int
    active_users_7d: int
    total_conversations: int
    total_messages: int
    total_omics_uploads: int
    total_meals: int


class FeatureTokenDetail(BaseModel):
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0
    call_count: int = 0


class AdminTokenStats(BaseModel):
    total_prompt_tokens: int = 0
    total_completion_tokens: int = 0
    total_tokens: int = 0
    total_calls: int = 0
    summary_task_tokens: int = 0
    summary_task_count: int = 0
    by_feature: dict[str, FeatureTokenDetail] = {}


class SummaryTaskItem(BaseModel):
    task_id: str
    user_id: int
    username: str | None = None
    status: str
    stage: str | None = None
    token_used: int = 0
    created_at: datetime | None = None
    updated_at: datetime | None = None


class UserTokenItem(BaseModel):
    user_id: int
    username: str | None = None
    phone: str
    audit_tokens: int = 0
    audit_calls: int = 0
    summary_tokens: int = 0
    summary_calls: int = 0
    total_tokens: int = 0


class AdminTokenDetails(BaseModel):
    by_user: list[UserTokenItem] = []
    recent_tasks: list[SummaryTaskItem] = []


class AdminUserItem(BaseModel):
    id: int
    phone: str
    username: str | None = None
    is_admin: bool = False
    created_at: datetime | None = None
    conversation_count: int = 0
    message_count: int = 0
    last_active: datetime | None = None


class AdminConversationItem(BaseModel):
    id: int
    user_id: int
    username: str | None = None
    title: str | None = None
    message_count: int = 0
    created_at: datetime | None = None
    updated_at: datetime | None = None


class AdminOmicsItem(BaseModel):
    id: int
    user_id: int
    username: str | None = None
    omics_type: str
    file_name: str | None = None
    file_size: int | None = None
    risk_level: str | None = None
    llm_summary: str | None = None
    created_at: datetime | None = None
