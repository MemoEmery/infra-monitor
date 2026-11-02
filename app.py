from flask import Flask
import psutil
import requests
import socket
import platform

app = Flask(__name__)

# ========================================================
# NOME DA EQUIPE (Altere para testar o CI/CD!)
EQUIPE = "Equipe Alpha"
# ========================================================

def obter_conselho_devops():
    try:
        # Consome uma API externa de conselhos (Slip Advice API)
        resposta = requests.get("https://api.adviceslip.com/advice", timeout=2)
        return resposta.json()['slip']['advice']
    except:
        return "Automatize tudo."

@app.route('/')
def home():
    memoria = psutil.virtual_memory()
    cpu_percent = psutil.cpu_percent(interval=0.1)
    
    html = f"""
    <html>
    <body style="font-family: Arial, sans-serif; background: #f4f4f9; padding: 20px;">
        <h2>🚀 Painel de Infra - {EQUIPE}</h2>
        <hr>
        <h3>🖥️ Telemetria do Servidor</h3>
        <ul>
            <li><b>Hostname (ID Container):</b> {socket.gethostname()}</li>
            <li><b>Arquitetura:</b> {platform.machine()}</li>
            <li><b>Uso de CPU:</b> {cpu_percent}%</li>
            <li><b>Uso de RAM:</b> {memoria.percent}%</li>
        </ul>
        <h3>💡 Conselho DevOps do Dia:</h3>
        <p style="color: #0056b3; font-style: italic;">"{obter_conselho_devops()}"</p>
    </body>
    </html>
    """
    return html

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)