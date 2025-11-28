# Pet Loss and Found Feature Walkthrough

I have implemented the "Pet Loss and Found" feature, allowing users to upload photos of found pets, search for lost pets using image similarity, and report lost pets with detailed information.

## Changes

### Database
-   **New Table `pets`**: Stores details of pets.
    -   Added `images` (text[]), `lat`, `lng` (float).
    -   Added `pet_name`, `owner_name`, `pet_type`, `breed`, `color`, `marks`, `reward`, `user_id` for lost pet listings.
    -   **Added `last_seen_at` (timestamptz)**: Stores the date and time when the pet was last seen or found.
-   **New Table `pet_embeddings`**: Stores vector embeddings.
-   **New Table `notifications`**: Stores alerts for users (e.g., when a found pet matches their lost pet).
-   **Function `match_pets`**: Updated to support status filtering and return owner info.

### Backend Service (`services/pet-detection`)
-   **`main.py`**: FastAPI service for embedding generation (ResNet18).

### Frontend (`app/find-pet`)
-   **`page.tsx`**:
    -   **"I Found a Pet"**: Upload multiple photos, location, **Date/Time Found**.
    -   **"I Lost a Pet"**: Search by image and location.
    -   **"Add Lost Pet" Button**: Opens a **Wizard Form** (`LostPetForm`) to report a lost pet (requires login).
-   **`components/pet/lost-pet-form.tsx`**: Step-by-step form for reporting lost pets (Details -> Photos -> Location & **Time** -> Owner Info).

### API Routes
-   **`app/api/pet/found/route.ts`**: Handles found pet registration. **Triggers alerts** if matches are found against 'LOST' pets. Now saves `last_seen_at`.
-   **`app/api/pet/lost/route.ts`**: Handles lost pet registration (uploads, embeddings, saves to DB). Now saves `last_seen_at`.
-   **`app/api/pet/search/route.ts`**: Handles lost pet search.

## Verification Results

### Manual Verification Steps

1.  **Database Migration (Required)**:
    > [!IMPORTANT]
    > You must run the following SQL in your Supabase SQL Editor to add the new column:
    ```sql
    ALTER TABLE pets ADD COLUMN if not exists last_seen_at timestamptz;
    ```

2.  **Start the Python Service**:
    ```bash
    cd services/pet-detection
    # ... setup venv ...
    uvicorn main:app --reload --port 8000
    ```

3.  **Test "Report Lost Pet"**:
    -   Go to `/find-pet`.
    -   Click "แจ้งสัตว์หาย".
    -   Fill in details, including **Date and Time Lost**.
    -   Submit and verify success.

4.  **Test "Found Pet"**:
    -   Go to `/find-pet`.
    -   Select "ฉันพบสัตว์เลี้ยง".
    -   Fill in details, including **Date and Time Found**.
    -   Submit.

5.  **Verify Display**:
    -   Search for a pet and verify the "Found when: ..." (พบเมื่อ) date is displayed on the card.

## Next Steps
-   Implement a Notification Center in the UI to display the alerts.
-   Deploy Python service.
