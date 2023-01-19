import { useEffect, useState } from 'react'
import { Container, Row, Col, Form, InputGroup, Stack, Button, Alert } from 'react-bootstrap';
import NavMenu from './components/NavMenu';
import tokenAbi from './components/abi/ShareHolder.json';

function App() {

  const [walletAddress, setWalletAddress] = useState("");

  useEffect(() => {
    const init = async () => {
      var contractAddress = "0x0";
      const method = "eth_requestAccounts";
      const accounts = await window.ethereum.request({ method })
      if (accounts.length > 0) {
        setWalletAddress(accounts[0]);
      }
    }
    init();
  }, [walletAddress])
  
  return (
    <div className="App">
      <Container>
        <NavMenu />
        {walletAddress.length > 0
        ?
        <Form>
          <Form.Group className='mb-3'>
            <Row className='justify-content-xs-center'>
              <Col xs={12} md={6}>
                <Alert variant="success">
                  <Alert.Heading>Check if a particular wallet does have a main task</Alert.Heading>
                    <p>
                      Mollit est exercitation consequat sunt magna est sunt duis deserunt tempor irure aliqua. Ea aute irure occaecat quis tempor in occaecat. Cupidatat labore sint minim voluptate irure veniam.
                    </p>
                    <hr />
                    <p className="mb-0">
                      <Stack direction="horizontal" gap={3}>
                        <Form.Control className="me-auto" placeholder="Wallet Address" />
                        <Button variant="secondary">Submit</Button>
                      </Stack>
                    </p>
                </Alert>
              </Col>
              <Col xs={12} md={6}>
                <Alert variant="success">
                  <Alert.Heading>Check if a particular wallet does have a main task</Alert.Heading>
                    <p>
                      Mollit est exercitation consequat sunt magna est sunt duis deserunt tempor irure aliqua. Ea aute irure occaecat quis tempor in occaecat. Cupidatat labore sint minim voluptate irure veniam.
                    </p>
                    <hr />
                    <p className="mb-0">
                      <Stack direction="horizontal" gap={3}>
                        <Form.Control className="me-auto" placeholder="Wallet Address" />
                        <Button variant="secondary">Submit</Button>
                      </Stack>
                    </p>
                </Alert>
              </Col>
            </Row>
          </Form.Group>
        </Form>
        :
        <></>
        }
      </Container>
    </div>
  );
}

export default App;
