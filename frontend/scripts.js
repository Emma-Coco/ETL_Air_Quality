const API_BASE = "http://localhost:8000";
let chart = null;

// --------------------------------------------------
// AIR QUALITY INTERPRETATION (PM2.5)
// --------------------------------------------------
function airQualityLabel(pm25) {
    if (pm25 <= 10) return { label: "Good", color: "green" };
    if (pm25 <= 25) return { label: "Moderate", color: "orange" };
    if (pm25 <= 50) return { label: "Poor", color: "red" };
    return { label: "Very poor", color: "darkred" };
}

// --------------------------------------------------
// LOAD TODAY DATA
// --------------------------------------------------
function loadToday() {
    fetch(`${API_BASE}/air-quality/today`)
        .then(res => res.ok ? res.json() : null)
        .then(data => {
            const container = document.getElementById("today");

            if (!data) {
                container.innerText = "No data available for today.";
                return;
            }

            const quality = airQualityLabel(data.pm2_5_avg);

            container.innerHTML = `
                <strong>Date:</strong> ${data.date}<br>
                PM2.5: ${data.pm2_5_avg} µg/m³<br>
                PM10: ${data.pm10_avg} µg/m³<br>
                NO₂: ${data.nitrogen_dioxide_avg} µg/m³<br><br>
                <strong style="color:${quality.color}">
                    Air quality: ${quality.label}
                </strong>
            `;
        })
        .catch(() => {
            document.getElementById("today").innerText =
                "Unable to load today's data.";
        });
}

// --------------------------------------------------
// LOAD DAILY HISTORY
// --------------------------------------------------
function loadDaily() {
    fetch(`${API_BASE}/air-quality/daily`)
        .then(res => res.json())
        .then(data => {
            const table = document.getElementById("daily-table");
            table.innerHTML = "";

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
        })
        .catch(() => {
            document.getElementById("daily-table").innerHTML =
                "<tr><td colspan='4'>Unable to load data</td></tr>";
        });
}

// --------------------------------------------------
// DRAW CHART
// --------------------------------------------------
function drawChart(labels, pm25, pm10, no2) {
    if (chart) {
        chart.destroy();
    }

    chart = new Chart(document.getElementById("chart"), {
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

// --------------------------------------------------
// INITIAL LOAD + AUTO REFRESH
// --------------------------------------------------
loadToday();
loadDaily();

setInterval(() => {
    loadToday();
    loadDaily();
}, 5 * 60 * 1000); // every 5 minutes
