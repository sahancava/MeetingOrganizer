import './App.css';
import { useEffect } from 'react'
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';
import Col from 'react-bootstrap/Col';
import NavMenu from './components/NavMenu';

import tokenAbi from './components/abi/ShareHolder.json';
import Web3 from 'web3';

function App() {

  const init = async () => {
    var contractAddress = "xxx";
    const web3 = new Web3(window.ethereum);
    const Contract = new web3.eth.Contract(tokenAbi, contractAddress);
    setTimeout(async () => {
      const data = await Contract.methods.name().call()
      console.log('data: ', data)
    }, 500);
  }
  useEffect(() => {
    setTimeout(() => {
      init();
    }, 1000);
  })
  return (
    <div className="App">
      <Container>
        <NavMenu />
        <Row style={{backgroundColor: 'transparent', marginTop: '2%', border: '1px solid white'}}>
          <Col>Read Functions</Col>
          <Col>Write Functions</Col>
        </Row>
        <Row style={{backgroundColor: 'transparent', marginTop: '2%', border: '1px solid white'}}>
          <Col className="col-md-6">
            <Col className="col-md-12">
              Read Functions
            </Col>
            <Col className="col-md-12">
              Read Functions
            </Col>
          </Col>
          <Col className="col-md-6">
            <Col className="col-md-12">
              Write Functions
            </Col>
            <Col className="col-md-12">
              Write Functions
            </Col>
          </Col>
        </Row>
      </Container>
    </div>
  );
}

export default App;
