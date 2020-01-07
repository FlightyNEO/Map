//
//  SmartTarget.swift
//  Map
//
//  Created by Arkadiy Grigoryanc on 17.12.2019.
//

import CoreLocation

// MARK: - Struct
struct SmartTarget
{

	// MARK: ...Private properties
	private let dateOfCreated: Date

	// MARK: ...Properties
	let uid: String
	var title: String
	var coordinates: CLLocationCoordinate2D
	var address: String?
	var radius: Double?

	var numberOfVisits = 0
	var timeInside: TimeInterval = 0
	var inside: Bool

	var entryDate: Date? {
		didSet {
			if entryDate != nil {
				numberOfVisits += 1
			}
		}
	}
	var exitDate: Date? {
		didSet {
			if exitDate != nil {
				timeInside += exitDate?.timeIntervalSince(entryDate ?? Date()) ?? 0
				entryDate = nil
				exitDate = nil
			}
		}
	}

	private enum CodingKeys: String, CodingKey
	{
		case uid
		case title
		case coordinates
		case dateOfCreated
		case address
		case radius
		case numberOfVisits
		case timeInside
		case inside
		case entryDate
		case exitDate
	}

	// MARK: ...Initialization
	init(uid: String = UUID().uuidString,
		 title: String,
		 coordinates: CLLocationCoordinate2D,
		 inside: Bool,
		 address: String? = nil) {

		self.uid = uid
		self.title = title
		self.coordinates = coordinates
		self.dateOfCreated = Date()
		self.inside = inside
		self.address = address
	}
}

// MARK: - Codable
extension SmartTarget: Codable
{
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		uid = try container.decode(String.self, forKey: .uid)
		title = try container.decode(String.self, forKey: .title)
		coordinates = try container.decode(CLLocationCoordinate2D.self, forKey: .coordinates)
		dateOfCreated = try container.decode(Date.self, forKey: .dateOfCreated)
		address = try? container.decode(String.self, forKey: .address)
		radius = try? container.decode(Double.self, forKey: .radius)
		numberOfVisits = try container.decode(Int.self, forKey: .numberOfVisits)
		timeInside = try container.decode(TimeInterval.self, forKey: .timeInside)
		inside = try container.decode(Bool.self, forKey: .inside)
		entryDate = try? container.decode(Date.self, forKey: .entryDate)
		exitDate = try? container.decode(Date.self, forKey: .exitDate)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(uid, forKey: .uid)
		try container.encode(title, forKey: .title)
		try container.encode(coordinates, forKey: .coordinates)
		try container.encode(dateOfCreated, forKey: .dateOfCreated)
		try container.encode(address, forKey: .address)
		try container.encode(radius, forKey: .radius)
		try container.encode(numberOfVisits, forKey: .numberOfVisits)
		try container.encode(timeInside, forKey: .timeInside)
		try container.encode(inside, forKey: .inside)
		try container.encode(entryDate, forKey: .entryDate)
		try container.encode(exitDate, forKey: .exitDate)
	}
}

// MARK: - Comparable
extension SmartTarget: Comparable
{
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.uid == rhs.uid
	}

	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.dateOfCreated < rhs.dateOfCreated
	}
}

extension SmartTarget: Identity
{
	static func === (lhs: Self, rhs: Self) -> Bool {
		lhs.uid == rhs.uid && lhs.address == rhs.address && lhs.radius == rhs.radius && lhs.title == rhs.title
	}

	static func !== (lhs: Self, rhs: Self) -> Bool {
		lhs.uid != rhs.uid || lhs.address != rhs.address || lhs.radius != rhs.radius || lhs.title != rhs.title
	}
}

// MARK: - Hashable
extension SmartTarget: Hashable
{
	func hash(into hasher: inout Hasher) {
		hasher.combine(uid)
	}
}

// MARK: - Custom string convertible
extension SmartTarget: CustomStringConvertible
{
	var description: String { "uid: " + uid + ", title: " + title }
}
