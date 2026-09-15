"""Normalize health-profile candidate payloads to PostgreSQL JSONB.

Revision ID: 0027_health_profile_candidate_jsonb
Revises: 0026_medical_assistant
Create Date: 2026-07-31
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision = "0027_health_profile_candidate_jsonb"
down_revision = "0026_medical_assistant"
branch_labels = None
depends_on = None


def _column_type_name(bind) -> str | None:
    return bind.execute(
        sa.text(
            """
            SELECT data_type
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'health_profile_candidates'
              AND column_name = 'proposed_value'
            """
        )
    ).scalar_one_or_none()


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql" or _column_type_name(bind) != "json":
        return
    op.alter_column(
        "health_profile_candidates",
        "proposed_value",
        existing_type=sa.JSON(),
        type_=postgresql.JSONB(),
        postgresql_using="proposed_value::jsonb",
    )


def downgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql" or _column_type_name(bind) != "jsonb":
        return
    op.alter_column(
        "health_profile_candidates",
        "proposed_value",
        existing_type=postgresql.JSONB(),
        type_=sa.JSON(),
        postgresql_using="proposed_value::json",
    )
