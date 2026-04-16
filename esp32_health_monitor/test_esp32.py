#!/usr/bin/env python3
"""
Test Script pour ESP32 Fall Detection System
Teste la connexion WiFi/TCP et reçoit les données des capteurs
"""

import socket
import json
import time
import sys
from datetime import datetime

# Configuration
ESP32_IP = "192.168.1.100"      # À adapter
ESP32_PORT = 5000
TIMEOUT = 5

class ESP32Tester:
    def __init__(self, ip, port):
        self.ip = ip
        self.port = port
        self.socket = None
        self.connected = False
        
    def connect(self):
        """Établir connexion TCP avec ESP32"""
        try:
            print(f"🔌 Connexion à {self.ip}:{self.port}...")
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(TIMEOUT)
            self.socket.connect((self.ip, self.port))
            self.connected = True
            print("✅ Connecté à ESP32!")
            return True
        except Exception as e:
            print(f"❌ Erreur connexion: {e}")
            return False
    
    def send_command(self, cmd):
        """Envoyer commande à ESP32"""
        try:
            if not self.connected:
                print("❌ Pas connecté")
                return False
            
            self.socket.send(cmd.encode() + b'\n')
            print(f"📤 Commande envoyée: {cmd}")
            
            # Attendre réponse
            response = self.socket.recv(1024).decode().strip()
            print(f"📥 Réponse: {response}")
            return True
        except Exception as e:
            print(f"❌ Erreur envoi: {e}")
            return False
    
    def receive_sensor_data(self, duration=10):
        """Recevoir données capteurs pendant X secondes"""
        print(f"\n📊 Réception des données ({duration}s)...")
        print("-" * 60)
        
        start_time = time.time()
        data_count = 0
        
        try:
            while time.time() - start_time < duration:
                data = self.socket.recv(1024).decode().strip()
                
                if data:
                    try:
                        parsed = json.loads(data)
                        data_count += 1
                        
                        # Afficher formattée
                        timestamp = datetime.now().strftime("%H:%M:%S")
                        accel_mag = (parsed['accel']['x']**2 + 
                                   parsed['accel']['y']**2 + 
                                   parsed['accel']['z']**2)**0.5
                        
                        print(f"[{timestamp}] #{data_count}")
                        print(f"  📍 Accel: X={parsed['accel']['x']:6.2f}g  Y={parsed['accel']['y']:6.2f}g  Z={parsed['accel']['z']:6.2f}g  (mag={accel_mag:.2f}g)")
                        print(f"  🔄 Gyro:  X={parsed['gyro']['x']:6.1f}°/s  Y={parsed['gyro']['y']:6.1f}°/s  Z={parsed['gyro']['z']:6.1f}°/s")
                        print(f"  🌡️  Temp: {parsed['temperature']:.1f}°C")
                        print(f"  📡 RSSI:  {parsed['signal_strength']} dBm")
                        
                        if parsed['isFalling']:
                            print(f"  🚨 FALL DETECTED!")
                        
                        print()
                    except json.JSONDecodeError:
                        print(f"⚠️  Données invalides: {data[:50]}")
                        
        except socket.timeout:
            print(f"⏱️  Timeout")
        except Exception as e:
            print(f"❌ Erreur réception: {e}")
        
        print("-" * 60)
        print(f"✅ {data_count} données reçues")
        return data_count
    
    def test_commands(self):
        """Tester les commandes TCP"""
        print("\n🧪 Test des commandes...")
        commands = ["PING", "STATUS", "LED_ON", "LED_OFF"]
        
        for cmd in commands:
            self.send_command(cmd)
            time.sleep(0.5)
    
    def close(self):
        """Fermer connexion"""
        if self.socket:
            self.socket.close()
            self.connected = False
            print("🔌 Connexion fermée")

def main():
    """Scénario de test complet"""
    
    print("=" * 60)
    print("  ESP32 Fall Detection System - Test Script")
    print("=" * 60)
    print()
    
    # Demander IP si besoin
    ip = ESP32_IP
    user_ip = input(f"Adresse IP ESP32 [{ip}]: ").strip()
    if user_ip:
        ip = user_ip
    
    # Créer tester
    tester = ESP32Tester(ip, ESP32_PORT)
    
    # Test 1: Connexion
    print("\n[TEST 1] Connexion TCP")
    if not tester.connect():
        print("❌ Impossible de se connecter. Vérifier:")
        print("   - ESP32 allumé et connecté WiFi")
        print("   - Serveur TCP sur port 5000")
        print("   - Firewall autorise port 5000")
        sys.exit(1)
    
    # Test 2: Commandes
    print("\n[TEST 2] Commandes TCP")
    tester.test_commands()
    
    # Test 3: Données capteurs
    print("\n[TEST 3] Réception données capteurs")
    data_count = tester.receive_sensor_data(duration=10)
    
    if data_count == 0:
        print("❌ Aucune donnée reçue. Vérifier:")
        print("   - MPU6050 et MLX90614 initialisés")
        print("   - Broches I2C correctes (21=SDA, 22=SCL)")
        print("   - Adresses I2C: 0x68 (MPU6050), 0x5A (MLX90614)")
    else:
        print(f"✅ {data_count} messages reçus avec succès!")
    
    # Fermer
    tester.close()
    
    print("\n" + "=" * 60)
    print("  Test terminé ✅")
    print("=" * 60)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⏸️  Test annulé")
        sys.exit(0)
