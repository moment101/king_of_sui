import "bootstrap/dist/css/bootstrap.min.css";
import { WalletKitProvider } from "@mysten/wallet-kit";
import CreateGameButton from "./components/CreateGameButton";
import NavBar from "./components/NavBar";
import CurrentRound from "./components/CurrentRound";
import LeaderBoard from "./components/LeaderBoard";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Col from "react-bootstrap/Col";

function App() {
  return (
    <>
      <WalletKitProvider>
        <Container>
          <NavBar />
          <Row>
            <Col>
              <CurrentRound />
            </Col>
            <Col></Col>
          </Row>
          <LeaderBoard />
          <CreateGameButton />
        </Container>
      </WalletKitProvider>
    </>
  );
}

export default App;
