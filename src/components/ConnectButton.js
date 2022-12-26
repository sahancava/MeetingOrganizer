import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import $ from 'jquery';
import Button from 'react-bootstrap/Button';
import 'bootstrap/dist/css/bootstrap.min.css';

const ConnectButton = () => {

    let provider, signer, decimals, signerAddress, signerBalance, contract;

    const checkChain = async (param) => {
        var chain = {
            chainId: '',
            rpc: '',
            explorer: ''
        };

        switch (param) {
            case 'testnet':
                chain.chainId = '0x61'
                chain.rpc = 'https://data-seed-prebsc-1-s3.binance.org:8545/'
                chain.explorer = 'https://testnet.bscscan.com/'
                break;
            case 'mainnet':
                chain.chainId = '0x38'
                chain.rpc = 'https://bsc-dataseed1.binance.org/'
                chain.explorer = 'https://bscscan.com/'
                break;
            case 'goerli':
                chain.chainId = '0x5'
                chain.rpc = 'https://goerli.infura.io/v3/dbe54da01c604e25beeec406b3a3df92'
                chain.explorer = 'https://bscscan.com/'
                break;
            default:
                break;
        }

        if (await window.ethereum?.chainId !== chain.chainId) {
            $('#characterList').css('display', 'none');
            $('#characterList_not_metamask').css('display', 'flex')
            $('#chainWarning').css('display', 'block');
            window.ethereum.request({
                method: "wallet_addEthereumChain",
                params: [{
                    chainId: chain.chainId,
                    rpcUrls: [chain.rpc],
                    chainName: "BSC MainNet",
                    nativeCurrency: {
                        name: "BNB",
                        symbol: "BNB",
                        decimals: 18
                    },
                    blockExplorerUrls: [chain.explorer]
                }]
            });
        }
    }

    async function readAddress() {
        const method = "eth_requestAccounts";
        const accounts = await window.ethereum.request({ method });
        provider = new ethers.providers.Web3Provider(window.ethereum);
        signer = provider.getSigner();
        if (window.innerWidth > 576) {
            document.getElementById("walletConnectButton").innerText = accounts[0];
        } else {
            document.getElementById("walletConnectButton").innerText = accounts[0].substring(0, 25) + '...';
        }

        return accounts[0];
    }

    function getSelectedAddress() {
        return window.ethereum?.selectedAddress;
    }

    const [address, setAddress] = useState(
        getSelectedAddress()
    );

    const connectWallet = async () => {
        const selectedAddress = await readAddress();
        setAddress(selectedAddress);
        window.location.reload(true);
    };

    const windowOnload = window.onload = (event) => {
        setTimeout(async function () {
            if ((await readAddress()).length > 0) {
                await checkChain('testnet');
                console.log(`You're connected to: ${await readAddress()}`);
            } else {
                console.log("Metamask is not connected");
            }
        }, 500);
    }

    useEffect(() => {
        setTimeout(async () => {
            windowOnload();
        }, 100);
    });

    window.ethereum.on("accountsChanged", async function (accounts) {
        window.location.reload();
    });
    window.ethereum.on("chainChanged", async function (accounts) {
        window.location.reload();
    });

    return (
        <button
            className="btn btn-primary text-truncate overflow-hidden text-nowrap w-100"
            style={{maxWidth: 500}}
            id="walletConnectButton"
            onClick={connectWallet}
        >
            Connect MetaMask
        </button>
    );

};

export { ConnectButton };
