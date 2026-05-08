import pytest


@pytest.mark.asyncio
async def test_create_server(auth_client):
    response = await auth_client.post("/api/v1/servers", json={
        "name": "Test Server",
        "description": "A test server",
    })
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test Server"
    assert "invite_code" in data


@pytest.mark.asyncio
async def test_list_servers(auth_client):
    await auth_client.post("/api/v1/servers", json={"name": "Server 1"})
    await auth_client.post("/api/v1/servers", json={"name": "Server 2"})
    response = await auth_client.get("/api/v1/servers")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 2


@pytest.mark.asyncio
async def test_create_channel(auth_client):
    server_resp = await auth_client.post("/api/v1/servers", json={"name": "Channel Test Server"})
    server_id = server_resp.json()["id"]

    response = await auth_client.post(f"/api/v1/servers/{server_id}/channels", json={
        "name": "general",
        "type": "text",
    })
    assert response.status_code == 201
    assert response.json()["name"] == "general"


@pytest.mark.asyncio
async def test_list_channels(auth_client):
    server_resp = await auth_client.post("/api/v1/servers", json={"name": "Channel List Server"})
    server_id = server_resp.json()["id"]

    await auth_client.post(f"/api/v1/servers/{server_id}/channels", json={"name": "ch1", "type": "text"})
    await auth_client.post(f"/api/v1/servers/{server_id}/channels", json={"name": "ch2", "type": "voice"})

    response = await auth_client.get(f"/api/v1/servers/{server_id}/channels")
    assert response.status_code == 200
    assert len(response.json()) >= 2


@pytest.mark.asyncio
async def test_send_message(auth_client):
    server_resp = await auth_client.post("/api/v1/servers", json={"name": "Msg Server"})
    server_id = server_resp.json()["id"]
    ch_resp = await auth_client.post(f"/api/v1/servers/{server_id}/channels", json={"name": "chat", "type": "text"})
    channel_id = ch_resp.json()["id"]

    response = await auth_client.post(f"/api/v1/channels/{channel_id}/messages", json={
        "content": "Hello, world!",
    })
    assert response.status_code == 201
    assert response.json()["content"] == "Hello, world!"


@pytest.mark.asyncio
async def test_list_messages(auth_client):
    server_resp = await auth_client.post("/api/v1/servers", json={"name": "MsgList Server"})
    server_id = server_resp.json()["id"]
    ch_resp = await auth_client.post(f"/api/v1/servers/{server_id}/channels", json={"name": "chat", "type": "text"})
    channel_id = ch_resp.json()["id"]

    await auth_client.post(f"/api/v1/channels/{channel_id}/messages", json={"content": "msg1"})
    await auth_client.post(f"/api/v1/channels/{channel_id}/messages", json={"content": "msg2"})

    response = await auth_client.get(f"/api/v1/channels/{channel_id}/messages")
    assert response.status_code == 200
    assert len(response.json()) >= 2
