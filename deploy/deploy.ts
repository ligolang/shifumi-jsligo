import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import shifumi from '../compiled/shifumi.json';
import { buf2hex } from "@taquito/utils";
import metadata from "./metadata.json";
import * as dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const rpc = process.env.RPC; //"http://127.0.0.1:8732"
const pk: string = process.env.ADMIN_PK || undefined;
const Tezos = new TezosToolkit(rpc);
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })

let shifumi_address = process.env.SHIFUMI_CONTRACT_ADDRESS || undefined;

async function orig() {

    let shifumi_store = {
        'metadata': MichelsonMap.fromLiteral({
            "": buf2hex(Buffer.from("tezos-storage:contents")),
            contents: buf2hex(Buffer.from(JSON.stringify(metadata))),
        }),
        'next_session' : 0,
        'sessions' : new MichelsonMap(),
    }

    try {
        // Originate an Random contract
        if (shifumi_address === undefined) {
            const shifumi_originated = await Tezos.contract.originate({
                code: shifumi,
                storage: shifumi_store,
            })
            console.log(`Waiting for SHIFUMI ${shifumi_originated.contractAddress} to be confirmed...`);
            await shifumi_originated.confirmation(2);
            console.log('confirmed SHIFUMI: ', shifumi_originated.contractAddress);
            shifumi_address = shifumi_originated.contractAddress;              
        }
       
        console.log("./tezos-client remember contract SHIFUMI", shifumi_address)
        // console.log("tezos-client transfer 0 from ", admin, " to ", advisor_address, " --entrypoint \"executeAlgorithm\" --arg \"Unit\"")

    } catch (error: any) {
        console.log(error)
        return process.exit(1)
    }
}

orig();
