// ARCH-04: 模型已拆分为独立文件
//
// - AuthModels.swift      → 认证相关 (AuthResponse, SubjectItem, LoginSubjectBody 等)
// - GlucoseModels.swift   → 血糖相关 (DashboardHealth, GlucosePoint 等)
// - MealModels.swift      → 膳食相关 (MealItem, MealPhoto, MealCreateBody 等)
// - HealthModels.swift    → 健康数据 (HealthDocument, TodayBriefing, HealthReports 等)
// - ChatModels.swift      → 聊天相关 (ChatMessage, ChatConversation, ChatResponse 等)
// - SettingsModels.swift  → 设置相关 (UserSettings, UpdateSettingsBody 等)
//
// 此文件保留以维持 project.pbxproj 引用兼容性。
