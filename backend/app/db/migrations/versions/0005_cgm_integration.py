"""add cgm integration bindings table

Revision ID: 0005_cgm_integration
Revises: 0004_activity_logs
Create Date: 2026-03-05 18:30:00
"""

from alembic import op
import sqlalchemy as sa

from app.db.compat import UUID

revision = "0005_cgm_integration"
down_revision = "0004_activity_logs"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "cgm_device_bindings",
        sa.Column("id", UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", UUID(as_uuid=True), nullable=False),
        sa.Column("provider", sa.String(32), nullable=False),
        sa.Column("phone", sa.String(32), nullable=True),
        sa.Column("device_sn", sa.String(64), nullable=True),
        sa.Column("device_id", sa.String(128), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.true(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("provider", "phone", name="uq_cgm_bindings_provider_phone"),
        sa.UniqueConstraint("provider", "device_sn", name="uq_cgm_bindings_provider_sn"),
        sa.UniqueConstraint("provider", "device_id", name="uq_cgm_bindings_provider_id"),
    )
    op.create_index("ix_cgm_bindings_user_provider", "cgm_device_bindings", ["user_id", "provider"], unique=False)
    op.create_index("ix_cgm_bindings_provider_phone", "cgm_device_bindings", ["provider", "phone"], unique=False)
    op.create_index("ix_cgm_bindings_provider_sn", "cgm_device_bindings", ["provider", "device_sn"], unique=False)
    op.create_index("ix_cgm_bindings_provider_id", "cgm_device_bindings", ["provider", "device_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_cgm_bindings_provider_id", table_name="cgm_device_bindings")
    op.drop_index("ix_cgm_bindings_provider_sn", table_name="cgm_device_bindings")
    op.drop_index("ix_cgm_bindings_provider_phone", table_name="cgm_device_bindings")
    op.drop_index("ix_cgm_bindings_user_provider", table_name="cgm_device_bindings")
    op.drop_table("cgm_device_bindings")
