import pytest


@pytest.mark.asyncio
async def test_create_dm_conversation(auth_client):
    register_resp = await auth_client.post("/api/v1/auth/register", json={
        "username": "dmuser",
        "email": "dm@example.com",
        "password": "securepassword123",
    })
    other_user_id = register_resp.json().get("user_id")

    if other_user_id:
        response = await auth_client.post(f"/api/v1/dm/conversations/{other_user_id}")
        assert response.status_code == 200
        assert "id" in response.json()


@pytest.mark.asyncio
async def test_health(client):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
