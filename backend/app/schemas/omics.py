"""Omics schemas — metabolomics upload + analysis results."""

from __future__ import annotations

from pydantic import BaseModel, Field


class MetaboliteItem(BaseModel):
    name: str
    value: float | None = None
    unit: str | None = None
    status: str | None = None  # "normal" / "high" / "low"


class MetabolomicsAnalysisResult(BaseModel):
    summary: str
    analysis: str
    risk_level: str = "未评估"  # "低风险" / "中风险" / "高风险"
    metabolites: list[MetaboliteItem] = []


class ModelAnalysisStatus(BaseModel):
    task_id: str
    status: str = "pending"  # "pending" / "running" / "completed" / "failed"
    result: dict | None = None


class ModelAnalysisSubmit(BaseModel):
    upload_id: int
    model_type: str = Field(default="metabolomics_risk", description="分析模型类型")
    parameters: dict = {}
