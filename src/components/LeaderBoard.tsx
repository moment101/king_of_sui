import Table from "react-bootstrap/Table";
import { JsonRpcProvider, devnetConnection } from "@mysten/sui.js";
import { devnetGameStorageAddress } from "../constants";
import "../App.css";

interface LeaderBoardItem {
  index: string;
  gameId: string;
  name: string;
  bidPrice: string;
  time: string;
  account: string;
  status: string;
}

const provider = new JsonRpcProvider(devnetConnection);
const txn = await provider.getObject({
  id: devnetGameStorageAddress,
  options: { showContent: true },
});

function LeaderBoard() {
  let games = txn["data"]["content"]["fields"]["games"];
  let items: LeaderBoardItem[] = [];

  for (let i = 0; i < games.length; i++) {
    let gameId = games[i]["fields"]["id"]["id"];
    let time = games[i]["fields"]["start_time"];
    let status = games[i]["fields"]["in_progress"];
    let kings = games[i]["fields"]["kings"];
    let lastKing = kings[kings.length - 1];

    console.log(lastKing);
    let name = lastKing["fields"]["name"];
    let bid = lastKing["fields"]["bid"];
    let account = lastKing["fields"]["account"];

    let item = {
      index: String(i + 1),
      gameId: gameId,
      name: name,
      bidPrice: bid,
      time: time,
      account: account,
      status: String(status),
    };
    items.push(item);
  }

  items = items.reverse();

  return (
    <Table striped bordered hover className="leaderBoard">
      <thead>
        <tr>
          <th>Round No.</th>
          <th>King Name</th>
          <th>Account</th>
          <th>Bid Price</th>
          <th>In Progress...</th>
        </tr>
      </thead>
      <tbody>
        {items.map((item, index) => (
          <tr key={item.gameId}>
            <td>{item.index}</td>
            <td>{item.name}</td>
            <td>{item.account}</td>
            <td>{item.bidPrice}</td>
            <td>{item.status}</td>
          </tr>
        ))}
      </tbody>
    </Table>
  );
}

export default LeaderBoard;
