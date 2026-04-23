import 'package:flutter_test/flutter_test.dart';
import 'package:fondue/features/pets/domain/claim_transfer_rules.dart';

void main() {
  group('claim/transfer rules', () {
    test('owner can accept only pending claim without active transfer', () {
      expect(
        canOwnerAcceptClaim(
          isOwner: true,
          claimStatus: 'pending',
          hasPendingTransfer: false,
        ),
        isTrue,
      );

      expect(
        canOwnerAcceptClaim(
          isOwner: true,
          claimStatus: 'accepted',
          hasPendingTransfer: false,
        ),
        isFalse,
      );

      expect(
        canOwnerAcceptClaim(
          isOwner: false,
          claimStatus: 'pending',
          hasPendingTransfer: false,
        ),
        isFalse,
      );

      expect(
        canOwnerAcceptClaim(
          isOwner: true,
          claimStatus: 'pending',
          hasPendingTransfer: true,
        ),
        isFalse,
      );
    });

    test('owner submit transfer requires accepted claim and no pending transfer', () {
      expect(
        canOwnerSubmitTransfer(
          isOwner: true,
          claimStatus: 'accepted',
          hasPendingTransfer: false,
        ),
        isTrue,
      );

      expect(
        canOwnerSubmitTransfer(
          isOwner: true,
          claimStatus: 'pending',
          hasPendingTransfer: false,
        ),
        isFalse,
      );

      expect(
        canOwnerSubmitTransfer(
          isOwner: true,
          claimStatus: 'accepted',
          hasPendingTransfer: true,
        ),
        isFalse,
      );
    });

    test('only designated claimant confirms pending transfer', () {
      expect(
        canClaimantConfirmTransfer(
          isDesignatedClaimant: true,
          transferStatus: 'pending_claimant_confirmation',
        ),
        isTrue,
      );

      expect(
        canClaimantConfirmTransfer(
          isDesignatedClaimant: false,
          transferStatus: 'pending_claimant_confirmation',
        ),
        isFalse,
      );

      expect(
        canClaimantConfirmTransfer(
          isDesignatedClaimant: true,
          transferStatus: 'confirmed',
        ),
        isFalse,
      );
    });
  });
}
