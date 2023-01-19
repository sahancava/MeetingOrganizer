import { useState, useCallback, useEffect } from 'react';
import $ from 'jquery';
import { ConnectButton } from './ConnectButton';
import Nav from 'react-bootstrap/Nav';

const NavMenu = () => {

    const [selectedAddress, setSelectedAddress] = useState();
    const addressChanged = useCallback((address) => {
        setSelectedAddress(address);
    }, []);

    let isMetaMaskInstalled = false;


    if (window.ethereum !== undefined && window.ethereum !== 'undefined') {
        isMetaMaskInstalled = true;
        window.ethereum.on("accountsChanged", async function (accounts) {
            if (accounts.length < 1) {
                document.getElementById('contentArea').setAttribute('style', 'display:none;');
            }
        });
    }
    useEffect(() => {
        setTimeout(() => {

            // $('head').append('<style>html:after{content:"";position:fixed;top:0;height:100%;left:0;right:0;z-index:-10;background-color:#273136;background-image:linear-gradient(180deg,rgba(50,70,80,.9) 0,#0d101b 100%);background-image:url("' + backgroundImages[Math.floor(Math.random() * backgroundImages.length)] + '");background-repeat:no-repeat;background-position:center;background-attachment:initial;height:100%;transition:background .2s linear;background-size:cover;}</style>');
            if (!isMetaMaskInstalled && window.location.pathname.indexOf('game') > -1) {
                $('#characterList').css('display', 'none');
                $('#chainWarning').attr('style', 'display: block;margin-bottom:20%');
            }
        }, 500);
    });
    return (
        <>
        <Nav style={{justifyContent: 'center'}} variant="pills" defaultActiveKey="/home">
          <Nav.Item>
          <div className="w-100 text-end">
                    {
                        isMetaMaskInstalled
                            ?
                            <ConnectButton id="connectButton" onChange={addressChanged}/>
                            :
                            <a id="playTheGameButton" href="https://metamask.io" role="button" className="neon-button neon-button__3 text-center w-100"
                               style={{maxWidth: 500}}
                            >Install MetaMask</a>
                    }
                </div>
          </Nav.Item>
        </Nav>
        </>
    );
}

export default NavMenu;