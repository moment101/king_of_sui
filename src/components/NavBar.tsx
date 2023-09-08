import Container from "react-bootstrap/Container";
import Nav from "react-bootstrap/Nav";
import Navbar from "react-bootstrap/Navbar";
import NavDropdown from "react-bootstrap/NavDropdown";
import Button from "react-bootstrap/Button";
import { ConnectToWallet } from "./ConnectButton";

function NavBar() {
  return (
    <Navbar expand="lg" className="bg-body-tertiary">
      <Container>
        <Navbar.Brand href="#home">King of Sui</Navbar.Brand>
        <ConnectToWallet />
      </Container>
    </Navbar>
  );
}

export default NavBar;
