"""
Seed the veterinary knowledge base with initial data for RAG.
Run: python seed-knowledge-base.py
"""
import json
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'pet-ai-service'))

from app.config import settings
from app.clients.ollama_client import OllamaClient

KNOWLEDGE_ENTRIES = [
    "Dogs normally have a temperature of 101-102.5°F. Fever above 103°F requires monitoring.",
    "Cats should not be given human painkillers like ibuprofen or acetaminophen as they are toxic.",
    "Signs of dehydration in pets: loss of skin elasticity, dry gums, sunken eyes, lethargy.",
    "Puppies need vaccinations at 6-8 weeks, 10-12 weeks, and 14-16 weeks of age.",
    "Kittens need vaccinations at 6-8 weeks, 10-12 weeks, and 14-16 weeks of age.",
    "Common dog allergies: food allergies (chicken, beef, dairy), environmental (pollen, dust), flea allergies.",
    "Common cat allergies: flea allergy dermatitis, food allergies, environmental allergies.",
    "Heartworm is transmitted by mosquitoes and can be fatal. Prevention is key with monthly medication.",
    "Signs of dental disease in pets: bad breath, yellow/brown teeth, bleeding gums, difficulty eating.",
    "Pet obesity: dogs should have a visible waist. Cats should have palpable ribs with slight fat cover.",
    "Ear infections in dogs: common in floppy-eared breeds. Signs: head shaking, scratching, odor.",
    "Fleas cause itching, tapeworms, and can lead to anemia in severe cases. Year-round prevention recommended.",
    "Ticks can transmit Lyme disease, Ehrlichiosis, and Anaplasmosis. Check pets after outdoor activities.",
    "Senior dogs (7+ years) should have bi-annual vet checkups including blood work.",
    "Senior cats (10+ years) should have bi-annual vet checkups including kidney and thyroid function.",
    "Signs of arthritis in pets: stiffness, limping, difficulty jumping, reluctance to walk.",
    "Toxic foods for dogs: chocolate, grapes, raisins, onions, garlic, xylitol, macadamia nuts.",
    "Toxic foods for cats: onions, garlic, grapes, raisins, chocolate, raw bread dough, alcohol.",
    "Common plants toxic to pets: lilies (cats), sago palm, tulips, azaleas, oleander.",
    "Signs of poisoning: vomiting, diarrhea, seizures, drooling, weakness, loss of coordination.",
]


async def seed():
    print("Seeding knowledge base...")
    client = OllamaClient(settings.embedding_model)

    for i, entry in enumerate(KNOWLEDGE_ENTRIES):
        try:
            embedding = await client.embed(entry)
            # In production, insert into PostgreSQL ai_knowledge_base table
            print(f"  [{i+1}/{len(KNOWLEDGE_ENTRIES)}] Embedded: {entry[:60]}...")
        except Exception as e:
            print(f"  [{i+1}/{len(KNOWLEDGE_ENTRIES)}] Failed: {e}")

    print(f"\nDone! {len(KNOWLEDGE_ENTRIES)} entries ready for RAG.")


if __name__ == "__main__":
    import asyncio
    asyncio.run(seed())
