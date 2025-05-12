const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Verify deployer balance
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH");

  // Deploy DoNotBuy contract
  const DoNotBuy = await hre.ethers.getContractFactory("DoNotBuy");
  const doNotBuy = await DoNotBuy.deploy();

  await doNotBuy.waitForDeployment();
  const contractAddress = await doNotBuy.getAddress();
  console.log("DoNotBuy deployed to:", contractAddress);

  // Optional: Verify contract on Linea explorer (if supported)
  if (hre.network.name === "linea") {
    console.log("Waiting for 5 confirmations before verification...");
    await doNotBuy.deploymentTransaction().wait(5);
    try {
      await hre.run("verify:verify", {
        address: contractAddress,
        constructorArguments: [],
      });
      console.log("Contract verified successfully");
    } catch (error) {
      console.error("Verification failed:", error);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });