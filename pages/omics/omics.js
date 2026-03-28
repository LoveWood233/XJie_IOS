Page({
  data: {
    activeTab: 0,
    tabs: [
      { key: 'proteomics', label: '蛋白组学' },
      { key: 'metabolomics', label: '代谢组学' },
      { key: 'genomics', label: '基因组学' },
    ],
    // 占位数据
    proteomics: {
      title: '蛋白组学',
      icon: '🧬',
      desc: '通过质谱分析技术检测血液中的蛋白质表达谱，识别疾病相关的生物标志物。',
      items: [
        { name: 'CRP (C-反应蛋白)', value: '--', unit: 'mg/L', status: 'pending' },
        { name: 'TNF-α (肿瘤坏死因子)', value: '--', unit: 'pg/mL', status: 'pending' },
        { name: 'IL-6 (白介素-6)', value: '--', unit: 'pg/mL', status: 'pending' },
        { name: 'Adiponectin (脂联素)', value: '--', unit: 'μg/mL', status: 'pending' },
      ],
    },
    metabolomics: {
      title: '代谢组学',
      icon: '⚗️',
      desc: '利用代谢物谱分析技术检测体内小分子代谢产物，反映机体代谢状态。',
      items: [
        { name: 'BCAA (支链氨基酸)', value: '--', unit: 'μmol/L', status: 'pending' },
        { name: 'TMAO (氧化三甲胺)', value: '--', unit: 'μmol/L', status: 'pending' },
        { name: 'Bile Acids (胆汁酸)', value: '--', unit: 'μmol/L', status: 'pending' },
        { name: 'Ceramides (神经酰胺)', value: '--', unit: 'nmol/L', status: 'pending' },
      ],
    },
    genomics: {
      title: '基因组学',
      icon: '🔬',
      desc: '基于全基因组关联分析 (GWAS)，评估个体遗传风险和药物基因组学特征。',
      items: [
        { name: 'TCF7L2 (2 型糖尿病风险)', value: '--', unit: '', status: 'pending' },
        { name: 'FTO (肥胖易感基因)', value: '--', unit: '', status: 'pending' },
        { name: 'APOE (脂代谢基因)', value: '--', unit: '', status: 'pending' },
        { name: 'MTHFR (叶酸代谢基因)', value: '--', unit: '', status: 'pending' },
      ],
    },
  },

  onLoad() {},

  switchTab(e) {
    this.setData({ activeTab: e.currentTarget.dataset.index });
  },
});
