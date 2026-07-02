import pytest
from app.services.symptom_analyzer import symptom_analyzer


@pytest.mark.asyncio
async def test_analyze_simple_symptom():
    result = await symptom_analyzer.analyze(
        text="My dog has been scratching his ear for 2 days",
        pet_species="dog",
        pet_age=3,
    )
    assert "risk_level" in result
    assert "possible_conditions" in result
    assert "recommendation" in result


@pytest.mark.asyncio
async def test_analyze_with_full_info():
    result = await symptom_analyzer.analyze(
        text="Cat is sneezing and has watery eyes",
        pet_species="cat",
        pet_age=5,
        pet_breed="Persian",
        pet_weight_kg=4.5,
    )
    assert result["confidence"] >= 0


@pytest.mark.asyncio
async def test_analyze_returns_emergency_flag():
    result = await symptom_analyzer.analyze(
        text="Dog has difficulty breathing and pale gums",
        pet_species="dog",
        pet_age=7,
    )
    assert "is_emergency" in result
