"""Add summary_tasks table for background AI summary generation.

Revision ID: 0008_summary_tasks
Revises: 0007_health_indicators
"""

from alembic import op
import sqlalchemy as sa

revision = "0008_summary_tasks"
down_revision = "0007_health_indicators"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "summary_tasks",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("user_id", sa.BigInteger, sa.ForeignKey("user_account.id"), nullable=False, index=True),
        sa.Column("status", sa.String(16), nullable=False, server_default="pending"),
        sa.Column("stage", sa.String(8), nullable=True),
        sa.Column("stage_current", sa.Integer, nullable=False, server_default="0"),
        sa.Column("stage_total", sa.Integer, nullable=False, server_default="0"),
        sa.Column("progress_pct", sa.Float, nullable=False, server_default="0"),
        sa.Column("token_used", sa.Integer, nullable=False, server_default="0"),
        sa.Column("error_message", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("summary_tasks")
