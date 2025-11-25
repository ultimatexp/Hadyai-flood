# SOS Flood Map - Verification Walkthrough

## Prerequisites
- Node.js 18+
- Supabase Project (configured in `.env.local`)

## Setup
1.  **Install Dependencies**:
    ```bash
    npm install
    ```
2.  **Run Development Server**:
    ```bash
    npm run dev
    ```
3.  Open [http://localhost:3000](http://localhost:3000) in your browser.

## Verification Scenarios

### 1. Victim Flow (Create SOS)
1.  On the Landing Page, click **"ขอความช่วยเหลือ (SOS)"**.
2.  **Step 1 (Location)**:
    - Click "ใช้ตำแหน่งปัจจุบัน" or drag the map to pin a location.
    - Add a landmark note (e.g., "Near 7-11").
    - Click "ถัดไป".
3.  **Step 2 (Info)**:
    - Enter Name (e.g., "Somchai").
    - Enter Phone Number.
    - Select Categories (e.g., "น้ำดื่ม", "อาหาร").
    - Select Urgency Level.
    - Click "ถัดไป".
4.  **Step 3 (Details)**:
    - Add a note.
    - Upload a photo (optional).
    - Click "ส่งคำขอความช่วยเหลือ".
5.  **Success**:
    - You should be redirected to the Case Detail page.
    - **Verify**: A green banner should appear with "ส่งคำขอสำเร็จ!" and a link to update the status.
    - **Action**: Copy the link or click "อัปเดตสถานะ" to test the owner flow.

### 2. Helper Flow (View & Help)
1.  On the Landing Page, click **"ฉันเป็นอาสา"**.
2.  **Helper Dashboard**:
    - You should see a map with pins for active cases.
    - You should see a list of cases at the bottom (mobile) or side (desktop).
3.  **View Case**:
    - Click on a pin or a list item.
    - Verify case details match what was entered.
4.  **Action**:
    - Click **"ฉันจะช่วยเคสนี้"**.
    - Confirm the dialog.
    - Verify status changes to "ACKNOWLEDGED" (รับเรื่องแล้ว).

### 3. Owner/Update Flow
1.  Use the **Update Link** saved from the Victim Flow (or copied from the green banner).
2.  Open the link (e.g., `/case/[id]/update?token=...`).
3.  **Update Status**:
    - Click **"ถึงที่เกิดเหตุ"**.
    - Verify status updates to "IN_PROGRESS".
    - Click **"ช่วยเหลือเสร็จสิ้น"**.
    - Verify status updates to "RESOLVED".
    - You should be redirected back to the detail page showing the new status.

## Mobile Responsiveness
- Open the app in mobile view (Chrome DevTools Device Mode).
- Verify buttons are touch-friendly.
- Verify the map works on mobile.
