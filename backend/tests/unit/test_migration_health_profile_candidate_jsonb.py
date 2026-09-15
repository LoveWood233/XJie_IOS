"""Regression contract for normalizing candidate payloads to PostgreSQL JSONB."""

from __future__ import annotations

import importlib


MIGRATION_MODULE = "app.db.migrations.versions.0027_health_profile_candidate_jsonb"


class _Result:
    def __init__(self, value: str | None):
        self._value = value

    def scalar_one_or_none(self) -> str | None:
        return self._value


class _Bind:
    class dialect:
        name = "postgresql"

    def __init__(self, column_type: str | None):
        self.column_type = column_type

    def execute(self, _statement):
        return _Result(self.column_type)


class _Operations:
    def __init__(self, column_type: str | None):
        self.bind = _Bind(column_type)
        self.alterations: list[tuple[tuple, dict]] = []

    def get_bind(self):
        return self.bind

    def alter_column(self, *args, **kwargs):
        self.alterations.append((args, kwargs))


def test_0027_migration_normalizes_only_legacy_json_candidate_payloads(monkeypatch):
    migration = importlib.import_module(MIGRATION_MODULE)
    assert migration.revision == "0027_health_profile_candidate_jsonb"
    assert migration.down_revision == "0026_medical_assistant"

    legacy_operations = _Operations("json")
    monkeypatch.setattr(migration, "op", legacy_operations)
    migration.upgrade()

    assert len(legacy_operations.alterations) == 1
    args, kwargs = legacy_operations.alterations[0]
    assert args == ("health_profile_candidates", "proposed_value")
    assert kwargs["postgresql_using"] == "proposed_value::jsonb"

    current_operations = _Operations("jsonb")
    monkeypatch.setattr(migration, "op", current_operations)
    migration.upgrade()
    assert current_operations.alterations == []
