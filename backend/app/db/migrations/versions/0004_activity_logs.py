"""add activity_logs table

Revision ID: 0004_activity_logs
Revises: 0003_intervention_levels
Create Date: 2026-03-05 00:00:00
"""

from alembic import op
import sqlalchemy as sa

from app.db.compat import JSONB, UUID

revision = "0004_activity_logs"
down_revision = "0003_intervention_levels"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "activity_logs",
        sa.Column("id", UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", UUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("action", sa.String(64), nullable=False),
        sa.Column("detail", JSONB(), nullable=False, server_default="{}"),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.String(512), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_activity_logs_user_created", "activity_logs", ["user_id", "created_at"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_activity_logs_user_created", table_name="activity_logs")
    op.drop_table("activity_logs")
