import { useState } from "react";
import Button from "react-bootstrap/Button";
import Form from "react-bootstrap/Form";
import Modal from "react-bootstrap/Modal";

import { TransactionBlock } from "@mysten/sui.js";
import { useWalletKit } from "@mysten/wallet-kit";
import { devnetPackageAddress, devnetGameStorageAddress } from "../constants";
import "../App.css";

function CreateGameButton() {
  const [name, setName] = useState("");
  const [price, setPrice] = useState("");

  const [show, setShow] = useState(false);

  const handleClose = () => setShow(false);
  const handleShow = () => setShow(true);

  const { signAndExecuteTransactionBlock } = useWalletKit();
  const handleCreateClick = async () => {
    const tx = new TransactionBlock();
    tx.setGasBudget(10000000);
    const [coin] = tx.splitCoins(tx.gas, [tx.pure(Number(price))]);
    tx.moveCall({
      target: devnetPackageAddress.concat("::game::create_game"),
      arguments: [
        tx.object(devnetGameStorageAddress),
        tx.pure(name),
        coin,
        tx.object("0x06"),
      ],
    });
    signAndExecuteTransactionBlock({ transactionBlock: tx });
  };

  return (
    <>
      <Button variant="dark" onClick={handleShow} className="createGameButton">
        Create New Round
      </Button>

      <Modal show={show} onHide={handleClose}>
        <Modal.Header closeButton>
          <Modal.Title>建立新局</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group
              className="mb-3"
              controlId="createGameForm.nameControlInput"
            >
              <Form.Label>您的名稱：</Form.Label>
              <Form.Control
                placeholder="Bob"
                autoFocus
                value={name}
                onChange={(event) => setName(event.target.value)}
              />
            </Form.Group>
            <Form.Group
              className="mb-3"
              controlId="createGameForm.priceControlInput"
            >
              <Form.Label>起始金額：</Form.Label>
              <Form.Control
                placeholder="1000"
                autoFocus
                value={price}
                onChange={(event) => setPrice(event.target.value)}
              />
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleClose}>
            Close
          </Button>
          <Button variant="primary" onClick={handleCreateClick}>
            Create
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  );
}

export default CreateGameButton;
