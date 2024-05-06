async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const GemAiSubscriptionService = await ethers.getContractFactory("GemAiSubscriptionService");
    const deployment = await GemAiSubscriptionService.deploy("0xFBE44caE91d7Df8382208fCdc1fE80E40FBc7e9a"); //GEMAI CONTRACT
  
    console.log("Token address:", deployment.address);
}
  
main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});