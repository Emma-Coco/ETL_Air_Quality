const API_BASE = "http://localhost:8000";

// -------------------------
// TODAY
// -------------------------
fetch(`${API_BASE}/air-quality/today`)
    .then(res => {
        if (!res.ok) throw new Error("No data for today");
        return res.json();
    })
    .then(data => {
        document.getElementById("today").innerHTML = `
            <strong>Date:</strong> ${data.date}<br>
            PM2.5: ${data.pm2_5_avg}<br>
            PM10: ${data.pm10_avg}<br>
            NO₂: ${data.nitrogen_dioxide_avg}
        `;
    })
    .catch(() => {
        document.getElementById("today").innerText =
            "No data available for today.";
    });

// -------------------------
// DAILY HISTORY
// -------------------------
fetch(`${API_BASE}/air-quality/daily`)
    .then(res => res.json())
    .then(data => {
        const table = document.getElementById("daily-table");

        const labels = [];
        const pm25 = [];
        const pm10 = [];
        const no2 = [];

        data.forEach(row => {
            table.innerHTML += `
                <tr>
                    <td>${row.date}</td>
                    <td>${row.pm2_5_avg}</td>
                    <td>${row.pm10_avg}</td>
                    <td>${row.nitrogen_dioxide_avg}</td>
                </tr>
            `;

            labels.push(row.date);
            pm25.push(row.pm2_5_avg);
            pm10.push(row.pm10_avg);
            no2.push(row.nitrogen_dioxide_avg);
        });

        drawChart(labels, pm25, pm10, no2);
    });

// -------------------------
// CHART
// -------------------------
function drawChart(labels, pm25, pm10, no2) {
    new Chart(document.getElementById("chart"), {
        type: "line",
        data: {
            labels: labels,
            datasets: [
                {
                    label: "PM2.5",
                    data: pm25,
                    borderColor: "red",
                    fill: false
                },
                {
                    label: "PM10",
                    data: pm10,
                    borderColor: "orange",
                    fill: false
                },
                {
                    label: "NO₂",
                    data: no2,
                    borderColor: "blue",
                    fill: false
                }
            ]
        }
    });
}
