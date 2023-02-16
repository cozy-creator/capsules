import express, { Express } from 'express';
import apiRouter from './routes';
import bodyParser from 'body-parser';
// import dotenv from 'dotenv';

// dotenv.config();

const app: Express = express();

app.use(express.static("public"));
app.use(express.static("static"));
app.use(bodyParser.urlencoded({ extended: true }));
app.use( bodyParser.json() );       
app.use( express.json() );       
app.use(apiRouter);


const port = process.env.PORT || 3002;


app.listen(port, () => {
  console.log(`⚡️[server]: Server is running at http://localhost:${port}`);
});