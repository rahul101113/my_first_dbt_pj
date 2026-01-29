{% docs fct_gpu_usage_comprehensive %}

## Overview
This model represents the **Gold Layer** of our GPU FinOps pipeline. It is strictly aligned with the **FinOps Open Cost & Usage Specification (FOCUS™) 1.0**. 

The goal of this model is to provide a cloud-agnostic view of AI compute efficiency by merging billing data with hardware-level telemetry.

### FOCUS 1.0 Column Mapping
We have mapped provider-specific fields to the following FOCUS standard columns:

| FOCUS Column | Business Logic |
| :--- | :--- |
| **ChargePeriodStart** | Normalized UTC start time of GPU usage. |
| **BilledCost** | The cash-basis cost (Unblended) for the compute hour. |
| **BillingAccountId** | The 12-digit AWS Account ID or Azure Subscription ID. |
| **ResourceId** | The unique identifier (Instance ID) for the GPU node. |
| **SkuId** | The cloud-specific instance type (e.g., p5.48xlarge). |

### Efficiency Extensions
Beyond the FOCUS 1.0 core, we have added "Efficiency Attributes" to track AI-specific ROI:
* **IdleWasteAmount:** Calculated as $BilledCost \times (1 - Utilization)$.
* **GpuModel:** A normalized hardware name (e.g., NVIDIA H100) mapped from the `dim_gpu_specs` seed.
* **EffectiveTflops:** The actual compute power realized based on utilization.

### Normalization Rules
1. **Timezone:** All timestamps are forced to **UTC**.
2. **Case Sensitivity:** All Resource IDs are **Lowercased** to ensure join integrity between billing and telemetry.
3. **Currency:** All costs are normalized to **USD**.
4. **Rounding:** Costs are maintained at **4 decimal places** for precision, then rounded to 2 for visualization.

### Audit & Compliance
This model supports **Row-Level Security (RLS)**. Access is restricted based on the `CostCenter` mapping provided by the Finance department. Unauthorized users will see a filtered view containing only their own project spend.

{% enddocs %}