from dataclasses import dataclass


@dataclass
class PowerModel:
    p_idle_w: float
    p_max_w: float
    def watts(self, cpu_percent: float) -> float:
        """Linear CPU→Power model."""
        return self.p_idle_w + (self.p_max_w - self.p_idle_w) * (cpu_percent/100.0)