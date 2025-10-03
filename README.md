# NGINX RTMP Proxy

This Docker setup creates an NGINX server with RTMP module that acts as a proxy for RTMP streams, similar to HTTP proxy_pass but for RTMP protocol.

## Features

- RTMP stream proxying/forwarding
- WHEP (WebRTC-HTTP Egress Protocol) playback proxying
- **SSL/TLS encryption with Let's Encrypt**
- **Automatic SSL certificate renewal**
- Web interface with HTTPS
- Optional stream recording
- Environment variable configuration
- Docker Compose orchestration

## Configuration

1. Edit the `.env` file to set your configuration:
   ```bash
   # SSL/Domain Configuration
   DOMAIN=your-proxy-domain.com
   EMAIL=your-email@example.com

   # RTMP Target Servers
   ORYX_SERVER_1=area.quantumatic.live/live
   ORYX_SERVER_2=your-target-server-2.com:1935
   
   # WHEP Servers
   WHEP_SERVER_1=area.quantumatic.live:443
   WHEP_HOST_1=area.quantumatic.live
   WHEP_SERVER_2=area-2.quantumatic.live:443
   WHEP_HOST_2=area-2.quantumatic.live
   ```

   **Important**: Make sure your domain points to your server's public IP address before running the SSL setup.

2. The NGINX configuration supports multiple applications:
   - `/live` - Allows both publishing and playback, forwards to **both** servers
   - `/proxy` - Only allows publishing, acts as pure proxy to **both** servers
   - `/server1` - Only publishes to ORYX_SERVER_1
   - `/server2` - Only publishes to ORYX_SERVER_2

## Usage

### First-time setup (with SSL):
```bash
./start.sh
```

### Manual SSL setup (if needed):
```bash
./setup-ssl.sh
```

### Start the service (regular use):
```bash
docker-compose up -d
```

### Stop the service:
```bash
docker-compose down
```

### View logs:
```bash
docker-compose logs -f nginx-rtmp
```

### Rebuild after changes:
```bash
docker-compose up -d --build
```

## RTMP URLs

- **Publish to both servers (proxy)**: `rtmp://localhost:1935/proxy/your-stream-key`
- **Publish to both servers (live)**: `rtmp://localhost:1935/live/your-stream-key`
- **Publish only to server 1**: `rtmp://localhost:1935/server1/your-stream-key`
- **Publish only to server 2**: `rtmp://localhost:1935/server2/your-stream-key`
- **Play from live**: `rtmp://localhost:1935/live/your-stream-key`

## WHEP Playback URLs

**With SSL (Recommended):**
- **WHEP Server 1**: `https://your-domain.com/rtc1/v1/whep/?app=live&stream=livestream`
- **WHEP Server 2**: `https://your-domain.com/rtc2/v1/whep/?app=live&stream=livestream`
- **Default WHEP**: `https://your-domain.com/rtc/v1/whep/?app=live&stream=livestream`

**Local Development (HTTP):**
- **WHEP Server 1**: `http://localhost/rtc1/v1/whep/?app=live&stream=livestream`
- **WHEP Server 2**: `http://localhost/rtc2/v1/whep/?app=live&stream=livestream`

**Original URLs:**
- **WHEP Server 1**: `https://area.quantumatic.live:443/rtc/v1/whep/?app=live&stream=livestream`
- **WHEP Server 2**: `https://area-2.quantumatic.live:443/rtc/v1/whep/?app=live&stream=livestream`

## Web Interface

- Access the web interface at: `http://localhost:8080`
- View RTMP statistics at: `http://localhost:8080/stat`

## Testing

You can test with OBS Studio or ffmpeg:

### Publishing with ffmpeg:

**To both servers:**
```bash
ffmpeg -re -i input.mp4 -c copy -f flv rtmp://localhost:1935/proxy/test
```

**To server 1 only:**
```bash
ffmpeg -re -i input.mp4 -c copy -f flv rtmp://localhost:1935/server1/test
```

**To server 2 only:**
```bash
ffmpeg -re -i input.mp4 -c copy -f flv rtmp://localhost:1935/server2/test
```

### Playing with ffplay (RTMP):
```bash
ffplay rtmp://localhost:1935/live/test
```

### Playing with WHEP (WebRTC in browser):

**WHEP Server 1 (SSL):**
```html
<video id="video1" autoplay controls></video>
<script>
async function startWhepPlayback1() {
    const pc = new RTCPeerConnection({
        iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
    });
    
    pc.addTransceiver('video', { direction: 'recvonly' });
    pc.addTransceiver('audio', { direction: 'recvonly' });
    
    const offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    
    const response = await fetch('https://your-domain.com/rtc1/v1/whep/?app=live&stream=livestream', {
        method: 'POST',
        headers: { 'Content-Type': 'application/sdp' },
        body: offer.sdp
    });
    
    const answer = await response.text();
    await pc.setRemoteDescription({ type: 'answer', sdp: answer });
    
    pc.ontrack = (event) => {
        document.getElementById('video1').srcObject = event.streams[0];
    };
}
</script>
```

**WHEP Server 2:**
```html
<video id="video2" autoplay controls></video>
<script>
async function startWhepPlayback2() {
    const pc = new RTCPeerConnection({
        iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
    });
    
    pc.addTransceiver('video', { direction: 'recvonly' });
    pc.addTransceiver('audio', { direction: 'recvonly' });
    
    const offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    
    const response = await fetch('https://your-domain.com/rtc2/v1/whep/?app=live&stream=livestream', {
        method: 'POST',
        headers: { 'Content-Type': 'application/sdp' },
        body: offer.sdp
    });
    
    const answer = await response.text();
    await pc.setRemoteDescription({ type: 'answer', sdp: answer });
    
    pc.ontrack = (event) => {
        document.getElementById('video2').srcObject = event.streams[0];
    };
}
</script>
```

## Environment Variables

**SSL Configuration:**
- `DOMAIN`: Your domain name for SSL certificate (e.g., `streaming.yourdomain.com`)
- `EMAIL`: Email address for Let's Encrypt notifications

**RTMP Servers:**
- `ORYX_SERVER_1`: First target RTMP server address (format: `host:port` or `host/path`)
- `ORYX_SERVER_2`: Second target RTMP server address (format: `host:port`)

**WHEP Servers:**
- `WHEP_SERVER_1`: First WHEP server address with port (format: `host:port`)
- `WHEP_HOST_1`: First WHEP server hostname for Host header
- `WHEP_SERVER_2`: Second WHEP server address with port (format: `host:port`)
- `WHEP_HOST_2`: Second WHEP server hostname for Host header

## SSL Certificate Management

### Automatic Renewal Setup (Monthly):
```bash
# Add to crontab for automatic monthly renewal
crontab -e

# Add this line (runs on 1st of every month at midnight):
0 0 1 * * /path/to/your/project/renew-ssl.sh >> /path/to/your/project/ssl-renewal.log 2>&1
```

### Manual Renewal:
```bash
docker-compose exec certbot certbot renew
docker-compose exec nginx-rtmp nginx -s reload
```

### Check Certificate Status:
```bash
docker-compose exec certbot certbot certificates
```

## Ports

- `1935`: RTMP port
- `80`: HTTP port (redirects to HTTPS)
- `443`: HTTPS port

## Volumes

- `recordings`: Stream recordings storage
- `logs`: NGINX log files