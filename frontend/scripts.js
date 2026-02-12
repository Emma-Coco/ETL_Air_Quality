const API_BASE = "/api"; // Proxy Nginx 
let chart = null;

/**
 * Interprétation de la qualité de l'air avec conseils santé
 */
function airQualityLabel(pm25) {
    if (pm25 <= 10) return { 
        label: "Excellente", 
        color: "#a78bfa", 
        advice: "L'air est pur. Profitez-en pour aérer ou faire du sport en extérieur." 
    };
    if (pm25 <= 25) return { 
        label: "Modérée", 
        color: "#8b5cf6", 
        advice: "Qualité acceptable. Les personnes sensibles devraient limiter les efforts intenses." 
    };
    return { 
        label: "Médiocre", 
        color: "#6d28d9", 
        advice: "Pollution marquée. Évitez les activités physiques intenses en extérieur aujourd'hui." 
    };
}

/**
 * Chargement des données d'aujourd'hui
 */
function loadToday() {
    fetch(`${API_BASE}/air-quality/today`)
        .then(res => res.ok ? res.json() : null)
        .then(data => {
            const container = document.getElementById("today");
            if (!data) {
                container.innerHTML = "<p>Aucune donnée disponible pour aujourd'hui.</p>";
                return;
            }

            const quality = airQualityLabel(data.pm2_5_avg);
            container.innerHTML = `
                <span class="badge-status" style="background:${quality.color}15; color:${quality.color}">
                    ● ${quality.label}
                </span>
                <span class="value-display">${data.pm2_5_avg}<small style="font-size:1rem; font-weight:300"> µg/m³</small></span>
                <div class="health-advice">${quality.advice}</div>
                <div style="display:flex; gap:30px; margin-top:25px; border-top:1px solid #f1f1f1; padding-top:20px">
                    <div><small style="color:var(--secondary-text)">PM10</small><br><strong>${data.pm10_avg}</strong></div>
                    <div><small style="color:var(--secondary-text)">NO₂</small><br><strong>${data.nitrogen_dioxide_avg}</strong></div>
                </div>
            `;
        })
        .catch(() => {
            document.getElementById("today").innerHTML = "Erreur lors du chargement des données.";
        });
}

/**
 * Chargement de l'historique et du graphique
 */
function loadDaily() {
    fetch(`${API_BASE}/air-quality/daily`)
        .then(res => res.json())
        .then(data => {
            const table = document.getElementById("daily-table");
            table.innerHTML = data.map(row => `
                <tr>
                    <td><strong>${row.date}</strong></td>
                    <td>${row.pm2_5_avg}</td>
                    <td>${row.pm10_avg}</td>
                    <td>${row.nitrogen_dioxide_avg}</td>
                </tr>
            `).join('');

            const labels = data.map(r => r.date);
            const pm25 = data.map(r => r.pm2_5_avg);
            const pm10 = data.map(r => r.pm10_avg);
            drawChart(labels, pm25, pm10);
        });
}

/**
 * Dessin du graphique Lilac
 */
function drawChart(labels, pm25, pm10) {
    const ctx = document.getElementById("chart").getContext("2d");
    if (chart) chart.destroy();

    chart = new Chart(ctx, {
        type: "line",
        data: {
            labels: labels,
            datasets: [{
                label: "PM2.5",
                data: pm25,
                borderColor: "#a78bfa",
                backgroundColor: "#a78bfa10",
                fill: true,
                tension: 0.4,
                pointRadius: 4
            }, {
                label: "PM10",
                data: pm10,
                borderColor: "#cbd5e1",
                borderDash: [5, 5],
                fill: false,
                tension: 0.4,
                pointRadius: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true, grid: { color: "#f1f1f1" } },
                x: { grid: { display: false } }
            }
        }
    });
}

// Initialisation
loadToday();
loadDaily();

// Rafraîchissement automatique toutes les 5 min 
setInterval(() => {
    loadToday();
    loadDaily();
}, 5 * 60 * 1000);