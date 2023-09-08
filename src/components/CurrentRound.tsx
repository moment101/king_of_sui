import Card from "react-bootstrap/Card";
import ListGroup from "react-bootstrap/ListGroup";
import { JsonRpcProvider, devnetConnection } from "@mysten/sui.js";
import {
  devnetPackageAddress,
  devnetGameStorageAddress,
  roundTimeMiliSecond,
} from "../constants";
import Button from "react-bootstrap/Button";
import { TransactionBlock } from "@mysten/sui.js";
import { useWalletKit } from "@mysten/wallet-kit";

import { useState } from "react";
import Form from "react-bootstrap/Form";
import Modal from "react-bootstrap/Modal";

import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Image from "react-bootstrap/Image";
import Row from "react-bootstrap/Row";
import "../App.css";

const provider = new JsonRpcProvider(devnetConnection);
const txn = await provider.getObject({
  id: devnetGameStorageAddress,
  options: { showContent: true },
});
console.log(txn);
const games = txn["data"]["content"]["fields"]["games"];
const lastGame = games[games.length - 1];

console.log(lastGame);

const kings = lastGame["fields"]["kings"];
const lastKing = kings[kings.length - 1];

console.log(lastKing);

export default function CurrentRound() {
  // 顯示出價視窗
  const [show, setShow] = useState(false);
  const handleClose = () => setShow(false);
  const handleShow = () => setShow(true);

  const [name, setName] = useState("");
  const [price, setPrice] = useState("");

  const { signAndExecuteTransactionBlock } = useWalletKit();
  const handleCloseGameClick = async () => {
    const tx = new TransactionBlock();
    tx.setGasBudget(10000000);
    tx.moveCall({
      target: devnetPackageAddress.concat("::game::stopGame"),
      arguments: [tx.object(devnetGameStorageAddress), tx.object("0x06")],
    });
    signAndExecuteTransactionBlock({ transactionBlock: tx });
  };

  const handleBidClick = async () => {
    const tx = new TransactionBlock();
    tx.setGasBudget(10000000);
    const [coin] = tx.splitCoins(tx.gas, [tx.pure(Number(price))]);
    tx.moveCall({
      target: devnetPackageAddress.concat("::game::replaceKing"),
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
      <Container className="currentRoundContent">
        <Row>
          <Col xs={4} md={4}>
            <Image src="src/assets/king_of_sui.png" rounded />
          </Col>
          <Col xs={4} md={4}></Col>
          <Col xs={4} md={4}>
            <Card style={{ width: "18rem" }}>
              <Card.Body>
                <Card.Title>{lastKing["fields"]["name"]}</Card.Title>
                <Card.Text>King</Card.Text>
              </Card.Body>
              <ListGroup className="list-group-flush">
                <ListGroup.Item>Round No.{games.length}</ListGroup.Item>
                <ListGroup.Item>
                  出價：{lastKing["fields"]["bid"]}
                </ListGroup.Item>
                <ListGroup.Item>
                  此局開始時間：
                  {formatTimeStamp(lastGame["fields"]["start_time"])}
                </ListGroup.Item>
                <ListGroup.Item>
                  現在時間：{formatTimeStampNow()}
                </ListGroup.Item>
                <ListGroup.Item>
                  剩餘時間：{timeLeft(lastGame["fields"]["start_time"])} 秒
                </ListGroup.Item>
                <ListGroup.Item>
                  狀態：
                  {currentStatus(
                    lastGame["fields"]["in_progress"],
                    timeLeft(lastGame["fields"]["start_time"])
                  )}
                </ListGroup.Item>
              </ListGroup>
              <Card.Body>
                {currentStatus(
                  lastGame["fields"]["in_progress"],
                  timeLeft(lastGame["fields"]["start_time"])
                ) == "進行中" && (
                  <Button variant="dark" onClick={handleShow}>
                    我要出價
                  </Button>
                )}

                {currentStatus(
                  lastGame["fields"]["in_progress"],
                  timeLeft(lastGame["fields"]["start_time"])
                ) == "逾時，等待關閉" && (
                  <Button variant="danger" onClick={handleCloseGameClick}>
                    關閉此局
                  </Button>
                )}
              </Card.Body>
            </Card>
          </Col>
        </Row>
      </Container>

      <Modal show={show} onHide={handleClose}>
        <Modal.Header closeButton>
          <Modal.Title>換我當王</Modal.Title>
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
              <Form.Label>出價金額：</Form.Label>
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
          <Button variant="primary" onClick={handleBidClick}>
            Bid
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  );
}

function formatTimeStamp(s: string): string {
  let unix_timestamp = Number(s);
  // Create a new JavaScript Date object based on the timestamp
  // Sui Move Clock is milliseconds
  var date = new Date(unix_timestamp);
  // Hours part from the timestamp
  var hours = date.getHours();
  // Minutes part from the timestamp
  var minutes = "0" + date.getMinutes();
  // Seconds part from the timestamp
  var seconds = "0" + date.getSeconds();

  // Will display time in 10:30:23 format
  var formattedTime =
    hours + ":" + minutes.substr(-2) + ":" + seconds.substr(-2);

  return formattedTime;
}

function timeLeft(s: string): string {
  let end_miliseconds = Number(s) + roundTimeMiliSecond;
  let date_now = new Date();
  let date_now_miliseconds = date_now.getTime();

  let delta = end_miliseconds - date_now_miliseconds;
  if (delta < 0) {
    return "0";
  } else {
    return String(delta / 1000);
  }
}

function formatTimeStampNow(): string {
  var date = new Date();
  var hours = date.getHours();
  var minutes = "0" + date.getMinutes();
  var seconds = "0" + date.getSeconds();
  var formattedTime =
    hours + ":" + minutes.substr(-2) + ":" + seconds.substr(-2);

  return formattedTime;
}

function currentStatus(in_progress: boolean, timeLeft: string): string {
  if (in_progress) {
    if (timeLeft == "0") {
      return "逾時，等待關閉";
    } else {
      return "進行中";
    }
  } else {
    return "結束";
  }
}
