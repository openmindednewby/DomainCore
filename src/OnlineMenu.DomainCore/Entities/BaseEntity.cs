using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using DomainCore.Events;

namespace DomainCore.Entities;

/// <summary>
/// Base entity for all aggregates and entities.
/// Provides both an int Id (PK), a Guid ExternalId for public exposure,
/// and common audit fields.
/// </summary>
public abstract class BaseEntity : HasDomainEventsBase
{
  /// <summary>
  /// Gets or sets the primary key identifier.
  /// </summary>
  [Key]
  [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
  public int Id { get; set; }

  /// <summary>
  /// Gets the external identifier used for public APIs.
  /// This is a GUID that is generated automatically.
  /// </summary>
  [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
  public Guid ExternalId { get; private set; }

  /// <summary>
  /// Gets the date and time when the entity was created.
  /// </summary>
  [Required]
  public DateTime CreatedDate { get; private set; } = DateTime.UtcNow;

  /// <summary>
  /// Gets the date and time when the entity was last updated.
  /// </summary>
  [Required]
  public DateTime LastUpdatedDate { get; private set; } = DateTime.UtcNow;

  /// <summary>
  /// Updates the LastUpdatedDate to the current UTC time.
  /// Call this method before saving changes.
  /// </summary>
  public void UpdateTimestamp()
  {
    LastUpdatedDate = DateTime.UtcNow;
  }
}
