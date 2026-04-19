import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * Ignition Module để deploy FoodTraceability Contract
 * 
 * Sử dụng:
 * - Local: npx hardhat ignition deploy ignition/modules/FoodTraceability.ts --network localhost
 * - Sepolia: npx hardhat ignition deploy ignition/modules/FoodTraceability.ts --network sepolia
 */
const FoodTraceabilityModule = buildModule("FoodTraceabilityModule", (m) => {
    // Deploy contract FoodTraceability
    // Constructor không cần tham số, người deploy tự động trở thành admin
    const foodTraceability = m.contract("FoodTraceability");

    // Return contract instance để có thể sử dụng sau này
    return { foodTraceability };
});

export default FoodTraceabilityModule;
