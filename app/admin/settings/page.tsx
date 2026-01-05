"use client";

import { useEffect, useState } from "react";
import { getAppSettings, updateAppSetting } from "@/app/actions/settings";
import { Settings, Save, Loader2 } from "lucide-react";

export default function SettingsPage() {
    const [helpPeopleEnabled, setHelpPeopleEnabled] = useState<boolean>(true);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        const fetchSettings = async () => {
            try {
                const value = await getAppSettings("help_people_enabled");
                if (value !== null) {
                    setHelpPeopleEnabled(value);
                }
            } catch (error) {
                console.error("Failed to load settings", error);
            } finally {
                setLoading(false);
            }
        };
        fetchSettings();
    }, []);

    const handleToggle = async () => {
        setSaving(true);
        const newValue = !helpPeopleEnabled;
        try {
            await updateAppSetting("help_people_enabled", newValue);
            setHelpPeopleEnabled(newValue);
        } catch (error) {
            console.error("Failed to update setting", error);
            alert("Failed to update setting");
        } finally {
            setSaving(false);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center p-12">
                <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
                    <Settings className="w-8 h-8 text-gray-600" />
                    System Settings
                </h1>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                <div className="flex items-center justify-between">
                    <div className="space-y-1">
                        <h3 className="text-lg font-medium text-gray-900">
                            Help People Feature
                        </h3>
                        <p className="text-sm text-gray-500">
                            Enable or disable the "Help People" (ช่วยคน) card on the frontpage.
                            When disabled, the card will be greyed out and unclickable.
                        </p>
                    </div>

                    <button
                        onClick={handleToggle}
                        disabled={saving}
                        className={`relative inline-flex h-8 w-14 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 ${helpPeopleEnabled ? 'bg-blue-600' : 'bg-gray-200'
                            }`}
                    >
                        <span
                            className={`inline-block h-6 w-6 transform rounded-full bg-white transition-transform ${helpPeopleEnabled ? 'translate-x-7' : 'translate-x-1'
                                } ${saving ? 'opacity-80' : ''}`}
                        />
                        {saving && (
                            <Loader2 className="absolute right-[-24px] w-5 h-5 animate-spin text-blue-600" />
                        )}
                    </button>
                </div>

                <div className="mt-4 p-4 bg-gray-50 rounded-lg border border-gray-100">
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                        <span className={`w-2 h-2 rounded-full ${helpPeopleEnabled ? 'bg-green-500' : 'bg-red-500'}`} />
                        Current Status: <span className="font-medium">{helpPeopleEnabled ? 'Active' : 'Disabled'}</span>
                    </div>
                </div>
            </div>
        </div>
    );
}
