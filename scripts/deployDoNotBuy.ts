const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Verify deployer balance
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH");

  // Deploy BankOfLinea contract
 // const BankOfLinea = await hre.ethers.getContractFactory("BankOfLinea");
  const DoNotBuy = await ethers.deployContract('DoNotBuy', {
    gasLimit: 5000000,
    //gasPrice: ethers.parseUnits('0.1', 'gwei') // Adjust based on Linea Mainnet
  });

 // const BankOfLinea = await BankOfLinea.deploy();

  await DoNotBuy.waitForDeployment();
  const contractAddress = await DoNotBuy.getAddress();
  console.log("DoNotBuy deployed to:", contractAddress);

  // Optional: Verify contract on Linea explorer (if supported)
  if (hre.network.name === "linea") {
    console.log("Waiting for 5 confirmations before verification...");
    await DoNotBuy.deploymentTransaction().wait(5);
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