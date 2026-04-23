bool canOwnerAcceptClaim({
  required bool isOwner,
  required String claimStatus,
  required bool hasPendingTransfer,
}) {
  if (!isOwner) return false;
  if (hasPendingTransfer) return false;
  return claimStatus == 'pending';
}

bool canOwnerRejectClaim({
  required bool isOwner,
  required String claimStatus,
}) {
  if (!isOwner) return false;
  return claimStatus == 'pending';
}

bool canOwnerSubmitTransfer({
  required bool isOwner,
  required String claimStatus,
  required bool hasPendingTransfer,
}) {
  if (!isOwner) return false;
  if (hasPendingTransfer) return false;
  return claimStatus == 'accepted';
}

bool canClaimantConfirmTransfer({
  required bool isDesignatedClaimant,
  required String transferStatus,
}) {
  if (!isDesignatedClaimant) return false;
  return transferStatus == 'pending_claimant_confirmation';
}
