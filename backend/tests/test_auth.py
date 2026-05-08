import pytest


@pytest.mark.asyncio
async def test_register(client):
    response = await client.post("/api/v1/auth/register", json={
        "username": "newuser",
        "email": "new@example.com",
        "password": "securepassword123",
    })
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_register_duplicate(client):
    await client.post("/api/v1/auth/register", json={
        "username": "dupuser",
        "email": "dup@example.com",
        "password": "securepassword123",
    })
    response = await client.post("/api/v1/auth/register", json={
        "username": "dupuser",
        "email": "dup@example.com",
        "password": "securepassword123",
    })
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_login(client):
    await client.post("/api/v1/auth/register", json={
        "username": "loginuser",
        "email": "login@example.com",
        "password": "securepassword123",
    })
    response = await client.post("/api/v1/auth/login?username=loginuser&password=securepassword123")
    assert response.status_code == 200
    assert "access_token" in response.json()


@pytest.mark.asyncio
async def test_get_me(auth_client):
    response = await auth_client.get("/api/v1/users/me")
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "testuser"
