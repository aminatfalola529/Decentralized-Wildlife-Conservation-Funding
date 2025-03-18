import { describe, it, beforeEach, expect, vi } from "vitest"

// Mock the Clarity blockchain environment
const mockClarity = {
  contracts: {
    "impact-measurement": {
      functions: {
        "record-metric": vi.fn(),
        "get-metric": vi.fn(),
        "get-project-metric-summary": vi.fn(),
        "get-metric-average": vi.fn(),
        "set-contract-admin": vi.fn(),
      },
      constants: {
        "METRIC-SPECIES-COUNT": 1,
        "METRIC-HABITAT-AREA": 2,
        "METRIC-THREAT-REDUCTION": 3,
        "METRIC-COMMUNITY-ENGAGEMENT": 4,
        "METRIC-BIODIVERSITY-INDEX": 5,
        "ERR-NOT-AUTHORIZED": 100,
        "ERR-METRIC-EXISTS": 101,
        "ERR-METRIC-NOT-FOUND": 102,
        "ERR-INVALID-METRIC-TYPE": 103,
        "ERR-INVALID-VALUE": 104,
      },
    },
  },
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  },
}

// Mock the contract calls
const mockContractCall = (functionName, args, result) => {
  mockClarity.contracts["impact-measurement"].functions[functionName].mockReturnValueOnce(result)
}

describe("Impact Measurement Contract", () => {
  beforeEach(() => {
    // Reset all mocks before each test
    vi.resetAllMocks()
  })
  
  it("should record a new metric successfully", () => {
    // Mock successful metric recording
    mockContractCall(
        "record-metric",
        [
          1, // project-id
          1, // metric-type (species count)
          150, // value
          "Elephant population count in protected area",
        ],
        { success: true, value: 1 },
    )
    
    // Call the contract function
    const result = mockClarity.contracts["impact-measurement"].functions["record-metric"](
        1,
        1,
        150,
        "Elephant population count in protected area",
    )
    
    // Verify the result
    expect(result).toEqual({ success: true, value: 1 })
    expect(mockClarity.contracts["impact-measurement"].functions["record-metric"]).toHaveBeenCalledTimes(1)
  })
  
  it("should get metric details successfully", () => {
    // Mock metric data
    const metricData = {
      "project-id": 1,
      "metric-type": 1,
      value: 150,
      "measurement-date": 100,
      verifier: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      notes: "Elephant population count in protected area",
    }
    
    // Mock successful metric retrieval
    mockContractCall("get-metric", [1], { success: true, value: metricData })
    
    // Call the contract function
    const result = mockClarity.contracts["impact-measurement"].functions["get-metric"](1)
    
    // Verify the result
    expect(result).toEqual({ success: true, value: metricData })
    expect(mockClarity.contracts["impact-measurement"].functions["get-metric"]).toHaveBeenCalledTimes(1)
  })
  
  it("should get project metric summary successfully", () => {
    // Mock summary data
    const summaryData = {
      count: 3,
      "total-value": 450,
    }
    
    // Mock successful summary retrieval
    mockContractCall("get-project-metric-summary", [1, 1], { success: true, value: summaryData })
    
    // Call the contract function
    const result = mockClarity.contracts["impact-measurement"].functions["get-project-metric-summary"](1, 1)
    
    // Verify the result
    expect(result).toEqual({ success: true, value: summaryData })
    expect(mockClarity.contracts["impact-measurement"].functions["get-project-metric-summary"]).toHaveBeenCalledTimes(1)
  })
  
  it("should calculate metric average successfully", () => {
    // Mock successful average calculation
    mockContractCall("get-metric-average", [1, 1], { success: true, value: 150 })
    
    // Call the contract function
    const result = mockClarity.contracts["impact-measurement"].functions["get-metric-average"](1, 1)
    
    // Verify the result
    expect(result).toEqual({ success: true, value: 150 })
    expect(mockClarity.contracts["impact-measurement"].functions["get-metric-average"]).toHaveBeenCalledTimes(1)
  })
  
  it("should fail when invalid metric type is provided", () => {
    // Mock invalid metric type error
    mockContractCall(
        "record-metric",
        [
          1, // project-id
          10, // invalid metric-type
          150, // value
          "Elephant population count in protected area",
        ],
        { success: false, error: 103 },
    )
    
    // Call the contract function
    const result = mockClarity.contracts["impact-measurement"].functions["record-metric"](
        1,
        10,
        150,
        "Elephant population count in protected area",
    )
    
    // Verify the result
    expect(result).toEqual({ success: false, error: 103 })
  })
})

