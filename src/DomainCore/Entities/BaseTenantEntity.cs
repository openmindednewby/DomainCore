using System.ComponentModel.DataAnnotations;

namespace DomainCore.Entities;

/// <summary>
/// Base entity for all tenant-scoped entities.
/// Inherits common fields and includes TenantId for multi-tenancy support.
/// </summary>
public abstract class BaseTenantEntity : BaseEntity
{
  /// <summary>
  /// Gets the user identifier from the JWT token.
  /// This represents the user who created or owns this entity.
  /// </summary>
  [Required]
  public Guid UserId { get; private set; }

  /// <summary>
  /// Gets the tenant identifier.
  /// This is used for multi-tenancy data isolation.
  /// </summary>
  [Required]
  public Guid TenantId { get; private set; }

  /// <summary>
  /// Sets the tenant ID for this entity.
  /// Can only be set once during entity creation.
  /// </summary>
  /// <param name="tenantId">The tenant identifier.</param>
  /// <exception cref="InvalidOperationException">Thrown when attempting to change an already set TenantId.</exception>
  public void SetTenant(Guid tenantId)
  {
    if (TenantId != Guid.Empty && TenantId != tenantId)
      throw new InvalidOperationException("TenantId cannot be changed once set.");

    TenantId = tenantId;
  }

  /// <summary>
  /// Sets the user ID for this entity.
  /// Can only be set once during entity creation.
  /// </summary>
  /// <param name="userId">The user identifier.</param>
  /// <exception cref="InvalidOperationException">Thrown when attempting to change an already set UserId.</exception>
  public void SetUser(Guid userId)
  {
    if (UserId != Guid.Empty && UserId != userId)
      throw new InvalidOperationException("UserId cannot be changed once set.");

    UserId = userId;
  }
}
