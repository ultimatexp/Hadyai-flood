
import React from 'react';

export const metadata = {
    title: 'Privacy Policy | Fondue: Report for Help',
    description: 'Privacy Policy for the Fondue mobile application.',
};

export default function PrivacyPolicyPage() {
    return (
        <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
            <div className="max-w-3xl mx-auto bg-white shadow-md rounded-lg p-8">
                <h1 className="text-3xl font-bold text-gray-900 mb-6">Privacy Policy</h1>
                <p className="text-sm text-gray-500 mb-8">Last updated: February 11, 2026</p>

                <div className="space-y-6 text-gray-700">
                    <section>
                        <h2 className="text-xl font-semibold text-gray-900 mb-3">1. Introduction</h2>
                        <p>
                            Welcome to <strong>Fondue: Report for Help</strong> ("we," "our," or "us").
                            We are committed to protecting your privacy and ensuring you have a positive experience on our app and website.
                            This policy explains how we collect, use, and safeguard your information.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-xl font-semibold text-gray-900 mb-3">2. Information We Collect</h2>
                        <ul className="list-disc pl-5 space-y-2">
                            <li>
                                <strong>Personal Information:</strong> When you report a lost or found pet, we may collect your contact information (such as phone number, Line ID, or Facebook profile) to facilitate reunification.
                            </li>
                            <li>
                                <strong>Pet Information & Images:</strong> We collect photos and descriptions of pets you upload. These images are analyzed by our AI to identify breed, color, and unique features.
                            </li>
                            <li>
                                <strong>Location Data:</strong> With your permission, we collect location data to pinpoint where a pet was lost or found. This helps display reports on our map feature.
                            </li>
                        </ul>
                    </section>

                    <section>
                        <h2 className="text-xl font-semibold text-gray-900 mb-3">3. How We Use Your Information</h2>
                        <p>We use the collected information to:</p>
                        <ul className="list-disc pl-5 space-y-2 mt-2">
                            <li>Match lost pets with found reports using AI technology.</li>
                            <li>Allow users to contact each other regarding lost/found pets.</li>
                            <li>Display pet sightings on a public map to alert the community.</li>
                            <li>Improve our AI models and search algorithms.</li>
                        </ul>
                    </section>

                    <section>
                        <h2 className="text-xl font-semibold text-gray-900 mb-3">4. Data Sharing and Visibility</h2>
                        <p>
                            <strong>Public Reports:</strong> Information you submit in a "Lost" or "Found" report (including pet photos, location, and contact details you choose to share) will be visible to other users of the app to help find the pet.
                        </p>
                        <p className="mt-2">
                            We do not sell your personal data to third parties. We may share data with service providers (like Cloud and AI providers) solely to operate the app's functionality.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-xl font-semibold text-gray-900 mb-3">5. Data Security</h2>
                        <p>
                            We implement reasonable security measures to protect your data. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-xl font-semibold text-gray-900 mb-3">6. Your Rights</h2>
                        <p>
                            You can request to delete your reports or account at any time by contacting us or using the delete features within the app.
                        </p>
                    </section>

                    <section>
                        <h2 className="text-xl font-semibold text-gray-900 mb-3">7. Contact Us</h2>
                        <p>
                            If you have any questions about this Privacy Policy, please contact us at:
                            <br />
                            <a href="mailto:support@thaiflood2025.com" className="text-blue-600 hover:underline">support@thaiflood2025.com</a>
                        </p>
                    </section>
                </div>

                <div className="mt-10 pt-6 border-t border-gray-200 text-center">
                    <p className="text-gray-500 text-sm">&copy; 2026 Fondue Team. All rights reserved.</p>
                </div>
            </div>
        </div>
    );
}
