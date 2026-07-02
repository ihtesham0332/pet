import pytest
from app.services.emergency_detector import emergency_detector


@pytest.mark.asyncio
async def test_critical_emergency_detected():
    result = await emergency_detector.check(
        symptoms=["dog is having seizures and blue gums"],
        pet_species="dog",
    )
    assert result["is_emergency"] is True
    assert result["severity"] == "critical"
    assert len(result["red_flags_detected"]) > 0
    assert result["vet_required"] is True


@pytest.mark.asyncio
async def test_no_emergency():
    result = await emergency_detector.check(
        symptoms=["mild itching on the skin"],
        pet_species="cat",
    )
    assert result["is_emergency"] is False


@pytest.mark.asyncio
async def test_poison_detected():
    result = await emergency_detector.check(
        symptoms=["cat ate chocolate and is vomiting"],
        pet_species="cat",
    )
    assert result["is_emergency"] is True


@pytest.mark.asyncio
async def test_multiple_symptoms():
    result = await emergency_detector.check(
        symptoms=["not eating for 3 days", "vomiting blood", "lethargic"],
        pet_species="dog",
    )
    assert result["is_emergency"] is True
