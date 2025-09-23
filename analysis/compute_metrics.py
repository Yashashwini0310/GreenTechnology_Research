from typing import Dict


def energy_it_kwh(avg_power_w: float, hours: float) -> float:
    return (avg_power_w * hours) / 1000.0


def energy_total_kwh(energy_it_kwh: float, pue: float) -> float:
    return energy_it_kwh * pue


def water_litres(energy_total_kwh: float, wue_l_per_kwh: float) -> float:
    return energy_total_kwh * wue_l_per_kwh


def requests_per_kwh(total_requests: int, energy_total_kwh: float) -> float:
    return total_requests / energy_total_kwh if energy_total_kwh else 0.0


def requests_per_litre(total_requests: int, water_l: float) -> float:
    return total_requests / water_l if water_l else 0.0


def cost_per_request(total_cost: float, total_requests: int) -> float:
    return total_cost / total_requests if total_requests else 0.0


def summarize_run(inputs: Dict) -> Dict:
    e_it = energy_it_kwh(inputs["avg_power_w"], inputs["hours"])
    e_total = energy_total_kwh(e_it, inputs["pue"])
    water = water_litres(e_total, inputs["wue"])
    return {
    "E_IT_kWh": e_it,
    "E_total_kWh": e_total,
    "water_L": water,
    "req_per_kWh": requests_per_kwh(inputs["total_requests"], e_total),
    "req_per_L": requests_per_litre(inputs["total_requests"], water),
    "cost_per_req": cost_per_request(inputs["total_cost"], inputs["total_requests"]),
    }