import React, { useEffect, useState } from "react";
import { fetchValidators } from "./novaNetAPI";

const ValidatorTable = () => {
    const [validators, setValidators] = useState([]);

    useEffect(() => {
        async function loadValidators() {
            const data = await fetchValidators();
            setValidators(data);
        }
        loadValidators();
    }, []);

    return (
        <div>
            <h2>🛡 NovaNet Live Validator Tracking</h2>
            <table>
                <thead>
                    <tr>
                        <th>Validator</th>
                        <th>Uptime (%)</th>
                        <th>Reputation Score</th>
                    </tr>
                </thead>
                <tbody>
                    {validators.map((val, index) => (
                        <tr key={index}>
                            <td>{val.validator}</td>
                            <td>{val.uptime}%</td>
                            <td>{val.reputation}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
};

export default ValidatorTable;
