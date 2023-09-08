import { ConnectButton, useWalletKit } from "@mysten/wallet-kit";

export function ConnectToWallet() {
  const { currentAccount } = useWalletKit();
  return (
    <ConnectButton connectText={"Connect Wallet"} connectedText={`Connected`} />
  );
}
